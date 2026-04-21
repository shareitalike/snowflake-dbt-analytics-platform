# Interview Notes: Enterprise Tasks

## "Why use Snowflake Tasks instead of Apache Airflow for CDC?"
**Answer:** While Airflow is excellent for enterprise-wide orchestration (e.g., triggering dbt Cloud, or cross-platform data movement), it is overkill for a 15-minute micro-batch CDC pipeline that lives entirely within Snowflake. Scheduling a 15-minute DAG in Airflow adds unnecessary network latency, API overhead, and worker contention. Native Snowflake Tasks are perfectly suited for tight, continuous micro-batches because they execute directly adjacent to the data and integrate natively with Stream offsets.

## "How did you prevent Tasks from consuming runaway credits?"
**Answer:** Two ways. First, I implemented the `WHEN SYSTEM$STREAM_HAS_DATA` clause on every task, meaning the warehouse literally doesn't turn on unless data is physically present in the stream. Second, I enforced `USER_TASK_TIMEOUT_MS`. A hung query (e.g., a bad Cartesian join in a MERGE) won't spin the warehouse indefinitely; the task will forcefully abort after 15 minutes, and our SLA monitor (`VW_DAG_SLA_BREACHES`) will alert the engineering team.

## "How did you handle task dependencies?"
**Answer:** I structured the tasks as a DAG. `TSK_CDC_ORDERS` cannot run until `TSK_CDC_CUSTOMER` and `TSK_CDC_PRODUCT` have completed successfully. This ensures absolute referential integrity in the Silver layer—an order will never attempt to attach to a customer that hasn't been merged yet.

**Here is the exact SQL code used to build this DAG:**

```sql
-- 1. The Parent Tasks (Dimensions) are scheduled by time.
CREATE OR REPLACE TASK TSK_CDC_CUSTOMER
    WAREHOUSE = WH_TRANSFORM
    SCHEDULE = '15 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('STR_SHOPIFY_CUSTOMER')
AS
    CALL SP_MERGE_CUSTOMER_SCD2();

CREATE OR REPLACE TASK TSK_CDC_PRODUCT
    WAREHOUSE = WH_TRANSFORM
    SCHEDULE = '15 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('STR_SHOPIFY_PRODUCT')
AS
    CALL SP_MERGE_PRODUCT_SCD2();

-- 2. The Child Task (Fact) uses the AFTER clause.
-- It has NO SCHEDULE. It triggers automatically when the parents succeed.
CREATE OR REPLACE TASK TSK_CDC_ORDERS
    WAREHOUSE = WH_TRANSFORM
    AFTER TSK_CDC_CUSTOMER, TSK_CDC_PRODUCT   -- The DAG Dependency!
    WHEN SYSTEM$STREAM_HAS_DATA('STR_SHOPIFY_ORDERS')
AS
    CALL SP_MERGE_ORDERS_TRANSACTIONAL();
```

*Note for Interview: You must explicitly mention that the child task does NOT get a `SCHEDULE`. It is triggered strictly by the `AFTER` clause when the parent tasks complete successfully.*

## "Is there any other way to handle dependencies natively in Snowflake without using Tasks and the `AFTER` clause?"
**Answer:** Yes! This is exactly where **Snowflake Dynamic Tables (DTs)** come into play. Tasks are an *imperative* orchestration model (you have to explicitly tell Snowflake the exact order of operations using the `AFTER` clause). Dynamic Tables use a *declarative* orchestration model.

### How dependencies work in Dynamic Tables:
With Dynamic Tables, you **do not** write dependencies or DAGs. You simply write the `SELECT` statement and define a `TARGET_LAG` (e.g., `15 minutes`). 
Snowflake's background engine automatically parses the SQL, understands the lineage (e.g., Fact Table A joins to Dimension Table B), and dynamically builds the DAG behind the scenes. It guarantees that the upstream tables will always be refreshed *before* the downstream tables to meet the target lag. 

### Why did you use Streams & Tasks instead of Dynamic Tables?
*(If the interviewer asks why you used Tasks instead of DTs, this is how you defend your architecture)*:
While Dynamic Tables are amazing for simple declarative pipelines, I chose Streams and Tasks for the Bronze-to-Silver CDC layer because our transformations require **complex, idempotent logic and error handling**. Dynamic tables do not currently support:
1. `TRY...CATCH` exception handling for bad records.
2. Stored Procedure invocations (like our `SP_MERGE_CUSTOMER_SCD2`).
3. Explicit quarantine routing to a Dead Letter Queue (`TB_DLQ_PAYLOADS`).
Dynamic Tables are great for the Silver-to-Gold layer (which we do with dbt), but for Bronze-to-Silver where data quality is highly volatile, the imperative control of Streams and Tasks is safer.

### Code Example: How Dynamic Tables Maintain a DAG Automatically
If an interviewer asks you to write the code proving how Dynamic Tables build a DAG without using `AFTER`, you show them this. 

Instead of an `AFTER` clause, you use `TARGET_LAG = DOWNSTREAM`. This tells Snowflake: *"I am a parent table. Do not refresh me on a time schedule. Refresh me exactly when my child table asks for data."*

```sql
-- 1. Create the Parent Dimension (Customer)
CREATE OR REPLACE DYNAMIC TABLE DT_CUSTOMER
  TARGET_LAG = DOWNSTREAM    -- <== This makes it a parent in the DAG!
  WAREHOUSE = WH_TRANSFORM
AS
  SELECT customer_id, first_name, last_name FROM TB_RAW_CUSTOMER;

-- 2. Create the Parent Dimension (Product)
CREATE OR REPLACE DYNAMIC TABLE DT_PRODUCT
  TARGET_LAG = DOWNSTREAM    -- <== This makes it a parent in the DAG!
  WAREHOUSE = WH_TRANSFORM
AS
  SELECT product_id, product_name, price FROM TB_RAW_PRODUCT;

-- 3. Create the Child Fact Table
CREATE OR REPLACE DYNAMIC TABLE DT_SALES_FACT
  TARGET_LAG = '15 MINUTE'   -- <== The child defines the schedule for the whole DAG
  WAREHOUSE = WH_TRANSFORM
AS
  SELECT 
    s.order_id,
    c.first_name,
    p.product_name,
    s.quantity
  FROM TB_RAW_SALES s
  JOIN DT_CUSTOMER c ON s.customer_id = c.customer_id -- Snowflake reads this join
  JOIN DT_PRODUCT p ON s.product_id = p.product_id;   -- and builds the DAG dependency!
```

**How Snowflake interprets this code:**
Because the `DT_SALES_FACT` explicitly joins to `DT_CUSTOMER` and `DT_PRODUCT`, Snowflake's Automated Refresh engine analyzes the SQL. It automatically creates a DAG where the child (`DT_SALES_FACT`) triggers the parents. Every 15 minutes, Snowflake automatically refreshes the Customer and Product tables *first*, and then immediately refreshes the Sales table. No `AFTER` clause required!
