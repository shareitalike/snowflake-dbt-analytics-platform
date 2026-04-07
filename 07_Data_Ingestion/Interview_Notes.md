# Interview Notes: Enterprise Data Ingestion

## "Why use Snowpipe Auto-Ingest instead of scheduling COPY INTO via Airflow or Tasks?"
**Answer:** Scheduling `COPY INTO` every 15 minutes is a "pull" architecture that wastes compute. If no files arrive, we still burn warehouse credits spinning up to check the stage. Snowpipe Auto-Ingest is a "push" architecture. It relies on S3 event notifications (via SNS/SQS) and utilizes Snowflake's serverless compute model. We only pay for the exact seconds of compute required to process the file, and we reduce latency from 15 minutes to near real-time (~10 seconds).

## "How do you handle 'poison pill' records that fail ingestion?"
**Answer:** We enforce `ON_ERROR = CONTINUE` in our `CREATE PIPE` definitions. If a CSV has 1,000,000 rows and 1 row has a formatting error, we ingest the 999,999 valid rows. To ensure we don't lose the bad row, we deployed a custom Stored Procedure (`SP_REPLAY_FAILED_FILES`) that queries `COPY_HISTORY`, replays the failure, and routes the bad payload into a dedicated Dead Letter Queue (DLQ) table in the `QUARANTINE` schema.

## "Why do you store everything as a VARIANT in the Bronze layer?"
**Answer:** Schema-on-Read. If Shopify adds a new field to their JSON payload, a strictly typed relational table would break our ingestion pipeline. By landing the payload as a `VARIANT` along with metadata (`metadata$filename`), we guarantee the ingestion never fails due to upstream schema drift. We then handle the schema enforcement downstream in the Silver layer using dbt.

## "How do you handle CSV Schema Evolution (e.g., adding a new column) in Snowflake?"
**Answer:** Because CSVs are flat and structured, schema evolution is the biggest risk. 
1. **The Modern Approach (`MATCH_BY_COLUMN_NAME`)**: If the CSV includes a header row, I configure the `COPY INTO` command to dynamically map columns by name by setting `PARSE_HEADER = TRUE` and `MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE`. If the upstream system scrambles the column order or adds a new column to the end, Snowflake maps the known columns perfectly and ignores the extra ones, preventing pipeline failure.
2. **The Legacy Approach (`ERROR_ON_COLUMN_COUNT_MISMATCH`)**: If the CSV relies on strict positional ordering, adding a new column crashes the `COPY INTO` by default. You can bypass this by setting `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE`. However, this is risky—if a column is added in the middle of the file (shifting everything to the right), Snowflake will load data into the wrong columns without throwing an error, leading to silent data corruption.
3. **The Architectural Pivot**: If an upstream system has a highly volatile schema, CSV is fundamentally the wrong file format. I would push back on the source team to emit JSON events instead, which allows us to natively ingest the payload into a `VARIANT` column and handle schema drift safely via Schema-on-Read.

## "If your DLQ error handling process runs periodically, doesn't that cause data to arrive late and create mismatches downstream?"
**Answer:** Yes, it absolutely creates late-arriving data—and the architecture is specifically designed to handle that gracefully. 
1. **Separation of Good and Bad Data**: We do not want 1 bad record to hold up 999,999 good records. The good data flows through to the BI dashboards in near real-time via Snowpipe.
2. **Handling the Delay Downstream (dbt)**: When the bad record is finally fixed and re-ingested from the DLQ hours later, it is treated as a late-arriving record. Our downstream dbt models are built as **Incremental `MERGE`** models (Accumulating Snapshots) rather than strict `APPEND` models. 
3. **Late-Arriving Dimensions**: If a fact (Order) arrives on time but its dimension (Customer) was quarantined in the DLQ, our Fact tables map that order to the `-1` (UNKNOWN) customer surrogate key. This ensures we don't lose the revenue in executive reports. When the customer record is finally fixed and loaded, the next dbt run automatically updates the Fact table with the correct customer key via the `MERGE` logic.

## "We usually prefer ELT (Extract, Load, Transform), but what if you *had* to apply transformations *during* the ingestion phase in Snowflake? How would you architect that?"
**Answer:** If business requirements dictate that data must be transformed before it lands in the raw table (ETL style), I would leverage the `SELECT` clause directly within the Snowpipe `COPY INTO` statement.
1. **Scalar Transformations in Snowpipe**: Snowflake allows you to query the external stage directly during ingestion. Instead of `COPY INTO table FROM @stage`, you write `COPY INTO table FROM (SELECT CAST($1 AS INT), UPPER($2) FROM @stage)`. This allows for lightweight transformations like data type casting, string manipulation, or JSON parsing on the fly without intermediate compute.
2. **External Functions for Complex Logic**: If the transformation requires complex logic (like real-time currency conversion or PII tokenization via a 3rd party tool), I would create a Snowflake **External Function** pointing to an AWS Lambda API. I can invoke that External Function directly inside the Snowpipe `SELECT` statement to transform the data as it streams in.
3. **The Trade-off**: I would caution the interviewer that this approach has limitations. Snowpipe transformations only support scalar operations—you cannot perform `JOIN`s, `GROUP BY`s, or aggregations during a `COPY INTO`. Furthermore, doing heavy transformations during ingestion makes replay difficult; if the transformation logic was flawed, the raw data is gone, and you must re-extract from the source system.

## "How exactly do you implement an External Function inside a Snowpipe COPY INTO statement? Can you walk me through the code?"
**Answer:** Implementing an external function requires establishing a secure trust relationship between Snowflake and an external API (like AWS API Gateway + Lambda). Here is the step-by-step code implementation:

**Step 1: Create the API Integration in Snowflake**
First, we create an integration object that securely stores the AWS IAM role credentials so Snowflake can authenticate to the API Gateway.
```sql
CREATE OR REPLACE API INTEGRATION aws_lambda_integration
    API_PROVIDER = aws_api_gateway
    API_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake_api_role'
    API_ALLOWED_PREFIXES = ('https://xyz123.execute-api.us-east-1.amazonaws.com/prod/')
    ENABLED = TRUE;
```

**Step 2: Create the External Function**
Next, we define the actual function that maps to the Lambda endpoint. Let's say we are tokenizing PII (like Credit Card numbers) in real-time.
```sql
CREATE OR REPLACE EXTERNAL FUNCTION ext_tokenize_pii(input_string VARCHAR)
    RETURNS VARCHAR
    API_INTEGRATION = aws_lambda_integration
    AS 'https://xyz123.execute-api.us-east-1.amazonaws.com/prod/tokenize';
```

**Step 3: Invoke the Function inside the Snowpipe**
Finally, we apply the external function inside the `SELECT` clause of our Snowpipe `COPY INTO` statement. As the file streams from S3, Snowflake sends batches of data to Lambda, Lambda returns the tokenized strings, and the masked data lands in the Bronze table.
```sql
CREATE OR REPLACE PIPE PIP_SECURE_PAYMENTS
    AUTO_INGEST = TRUE
    AWS_SNS_TOPIC = 'arn:aws:sns:us-east-1:123456789012:snowpipe-notifications'
AS
COPY INTO TB_RAW_PAYMENTS (
    payment_id,
    credit_card_token,  -- We do not store the raw card number!
    amount,
    ingestion_time
)
FROM (
    SELECT 
        $1:payment_id::VARCHAR,
        ext_tokenize_pii($1:credit_card_number::VARCHAR), -- External Function Call
        $1:amount::NUMBER,
        CURRENT_TIMESTAMP()
    FROM @STG_AWS_S3_PAYMENTS
)
FILE_FORMAT = (TYPE = 'JSON');
```
This architecture guarantees that highly sensitive raw data never even touches our Snowflake disk; it is tokenized in-flight during ingestion!

## "If Snowpark is so powerful, why did you use dbt for the Gold layer? Couldn't all the dbt work be done in Snowpark?"
**Answer:** Yes, theoretically, any SQL transformation done in dbt could be rewritten in Python using the Snowpark DataFrame API. However, doing so would be a massive architectural anti-pattern for three main reasons:
1. **Democratization of Data (The Skillset Bottleneck)**: Analytics Engineers and Data Analysts know SQL natively. By building the Gold layer (Facts and Dimensions) in dbt, we empower the Analytics team to own the business logic. If we forced all dimensional modeling into Python/Snowpark, we would lock out our analysts and create a massive bottleneck where every dashboard tweak requires a Data Engineer.
2. **dbt is Purpose-Built for Analytics**: dbt provides critical features out-of-the-box that we would have to build from scratch in Snowpark. This includes `ref()` based DAG lineage, auto-generated data dictionaries, automated testing (like `unique` and `not_null` assertions), and snapshotting for SCD Type 2 tracking. Reinventing the wheel in Python is a waste of engineering time.
3. **The Right Tool for the Job**: Snowpark is exceptional for tasks that SQL struggles with—like recursive JSON flattening, complex custom data validations, procedural logic, or calling external APIs. But for standard set-based transformations (joins, aggregations, window functions), SQL is the undisputed king. We use Snowpark for heavy engineering (Bronze to Silver), and dbt for business modeling (Silver to Gold).

## "Since you built this entire project yourself, why do you care about locking out analysts if you are the only one working on it?"
**Answer:** While I was the sole developer on this project, I intentionally designed the architecture to simulate a **highly scalable Enterprise environment**. I applied the principle of **Separation of Concerns**. When I was building the Snowpark framework, I was wearing my "Data Engineer" hat. When I moved to dbt, I wore my "Analytics Engineer" hat. I built the architecture this way because I want to prove that my design patterns can scale effortlessly to a team of 50 or 100 people. If I deploy this at a large company tomorrow, the Analytics team can immediately take over the dbt repository without ever needing to read my Python engineering code.

## "How exactly does your Snowpark framework detect new attributes and map them during normalization (Schema Evolution)?"
**Answer:** The dynamic schema evolution is handled by the **Schema Validator** class (`schema_validator.py`) combined with Snowflake's native schema evolution capabilities. Here is the technical breakdown:
1. **Dynamic Detection**: The Snowpark `SchemaValidator` evaluates the runtime schema of the incoming DataFrame (`df.schema.fields`) and compares it against an expected metadata dictionary. 
2. **Additive Evolution**: It loops through the incoming columns. If it detects a column that isn't in the metadata dictionary, instead of failing, it logs an "Additive Schema Evolution" event and allows the new column to persist in the DataFrame.
3. **Automatic Target Mapping**: Because the framework uses Snowpark's lazy evaluation, the new column remains in the DataFrame's projection. When the DataFrame is written to the Silver tier, Snowflake's native `ENABLE_SCHEMA_EVOLUTION = TRUE` parameter allows the target table to automatically alter itself, adding the new column and mapping the data without requiring a manual `ALTER TABLE` DDL execution by a DBA.

## "How exactly do you execute a Full Load (Disaster Recovery Backfill) if your architecture is built on Streams and Tasks?"
**Answer:** If the Silver layer becomes corrupt and we need to do a historical backfill from the Bronze layer, we cannot rely on the Stream because the Stream only contains recent deltas. Here is the exact SQL execution playbook for a Disaster Recovery Full Load:

```sql
-- Step 1: Suspend the automated CDC Task so it doesn't interfere
ALTER TASK DB_PROD_RAW.SC_BRONZE_SHOPIFY.TSK_MERGE_SHOPIFY SUSPEND;

-- Step 2: Execute the Bulk Overwrite. 
-- We bypass the Stream entirely and query the base Bronze table.
-- Using INSERT OVERWRITE is faster and cleaner than TRUNCATE + INSERT.
INSERT OVERWRITE INTO DB_PROD_CURATED.SC_SILVER_SHOPIFY.TB_SILVER_SHOPIFY_ORDERS
SELECT 
    raw_payload:id::VARCHAR AS order_id,
    raw_payload:customer_id::VARCHAR AS customer_id,
    raw_payload:total_price::NUMBER(38,2) AS total_price,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS;

-- Step 3: Reset the Stream Offset
-- Since we just loaded everything, we don't want the Stream to process any lingering 
-- deltas from before the overwrite. Recreating it resets the offset to CURRENT_TIMESTAMP.
CREATE OR REPLACE STREAM STR_SHOPIFY_ORDERS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS
    APPEND_ONLY = TRUE;

-- Step 4: Resume the Task for normal CDC operations
ALTER TASK DB_PROD_RAW.SC_BRONZE_SHOPIFY.TSK_MERGE_SHOPIFY RESUME;
```

## "What if it's not a total disaster, but just a specific window of data was omitted/missed by the stream? How do you backfill just that missing window?"
**Answer:** Because our entire CDC pipeline is built on **idempotent MERGE** statements, doing a targeted backfill is incredibly easy and safe. We do not need to do a full overwrite. There are two ways to handle this natively in Snowflake:

**Method 1: Targeted Manual MERGE (The fast way)**
Since the `MERGE` statement uses `QUALIFY ROW_NUMBER() = 1` for deduplication, we can simply run the exact same `MERGE` query manually, but point it directly at the Bronze table filtered for the missing time window instead of querying the stream. It will seamlessly insert the omitted records and safely ignore the records that were already processed successfully.
```sql
MERGE INTO DB_PROD_CURATED.SC_SILVER_SHOPIFY.TB_SILVER_SHOPIFY_ORDERS AS target
USING (
    SELECT 
        raw_payload:id::VARCHAR AS order_id,
        raw_payload:total_price::NUMBER AS total_price
    FROM DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS
    WHERE ingestion_timestamp BETWEEN '2023-10-01 12:00:00' AND '2023-10-01 14:00:00'
) AS source
ON target.order_id = source.order_id
WHEN NOT MATCHED THEN INSERT ...
```

**Method 2: Time-Travel Stream Recreation (The automated way)**
If we want the automated Task to handle the backfill itself, we can recreate the stream using **Snowflake Time Travel**, pointing it back to the exact timestamp right before the data went missing. 
```sql
CREATE OR REPLACE STREAM STR_SHOPIFY_ORDERS 
    ON TABLE DB_PROD_RAW.SC_BRONZE_SHOPIFY.TB_RAW_SHOPIFY_ORDERS
    AT (TIMESTAMP => '2023-10-01 12:00:00'::timestamp_tz)
    APPEND_ONLY = TRUE;
```
Once recreated, the next time the scheduled Task runs, it will sweep up all the data from that historical timestamp all the way to the present day. Because the `MERGE` is idempotent, it will not duplicate the data that was already loaded.

## "How exactly do you isolate a single bad record and move it to the DLQ during a CDC MERGE operation?"
**Answer:** This is actually one of the primary reasons we introduced **Snowpark** into the architecture! 
1. **The Pure SQL Limitation:** In a standard SQL `MERGE` statement, if one record fails (e.g., a type-casting error), the *entire transaction fails and rolls back*. SQL is set-based, making it incredibly difficult to isolate a single bad record out of a batch of 10,000 without failing the whole batch. 
2. **Our SQL Exception Handling:** In our pure SQL tasks (like `SP_MERGE_CUSTOMER_SCD2`), we use a `TRY...CATCH` (or `EXCEPTION WHEN OTHER`) block to trap the error, `ROLLBACK` the transaction (so the stream doesn't advance and we don't lose data), and log the batch failure via `SP_ROLLBACK_CHECKPOINT`.
3. **The Snowpark Solution:** To achieve true row-level isolation without failing the batch, we push that logic to the **Snowpark Framework** (`dlq_router.py`). Because Snowpark can evaluate dataframes programmatically and apply custom UDFs, it can detect the specific row that fails validation, route that single row to the `TB_DLQ_PAYLOADS` quarantine table, and allow the remaining 9,999 good records to successfully merge into the Silver layer!

## "Wait, your architecture documentation mentions both 'Controlled Failure' (requiring manual ALTER TABLE) and 'Automated Schema Evolution' (where Snowflake maps new attributes automatically). Which one is it?"
**Answer:** This is a key feature of a Polyglot Architecture. We actually implement **both** strategies, but we apply them selectively based on the criticality of the pipeline:

**1. Strategy A: The "Controlled Failure" (Used in SQL CDC Pipelines)**
For our highly critical Gold and Silver tables (like the `SP_MERGE_CUSTOMER_SCD2` pipeline), we use pure SQL `MERGE` statements. Pure SQL `MERGE` in Snowflake does *not* auto-evolve schemas. I designed it this way intentionally. If the upstream ERP system suddenly adds 5 junk columns, the SQL MERGE fails safely without corrupting the table. An engineer is alerted, reviews the columns, and manually runs `ALTER TABLE`. We do this because auto-adding random columns to critical financial tables could break downstream CEO dashboards in Power BI.

**2. Strategy B: "Automated Schema Evolution" (Used in Snowpark Pipelines)**
For our less rigid datasets (like raw JSON event streams processing through Snowpark), the Python `SchemaValidator` programmatically detects the new attribute. Because we use Snowpark DataFrames for the write operation, we pass that DataFrame down and use Snowflake's native `ENABLE_SCHEMA_EVOLUTION = TRUE` parameter. Snowpark automatically alters the target table and maps the new attribute dynamically, with zero DBA intervention required.

**Summary:** We use Controlled Failure to protect rigid financial models, and Automated Schema Evolution to rapidly process fluid JSON events.
