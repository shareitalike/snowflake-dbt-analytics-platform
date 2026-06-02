# Interview Notes: dbt (Data Build Tool)

## "Can dbt create Snowflake Streams or Tasks?"
**Answer:** Technically yes, but architecturally **NO**. 
Out of the box, dbt is designed to materialize Data Models (`views`, `tables`, `incremental`, `ephemeral`). It is not natively designed to manage Snowflake infrastructure objects like Streams, Tasks, Snowpipes, or Stages. 

While you *can* force dbt to execute DDL statements (like `CREATE STREAM`) by using `pre-hooks`, `post-hooks`, or custom macros, doing so is considered a **massive anti-pattern**. 
dbt is a Data Modeling tool, not an Infrastructure-as-Code (IaC) tool. Infrastructure like Streams, Tasks, and Roles should be managed by a tool like Terraform, Pulumi, or dedicated Snowflake CI/CD scripts.

## "What exactly is dbt responsible for in your architecture, and what is it NOT responsible for?"

### What dbt CAN do (and does brilliantly):
1. **The "T" in ELT:** It transforms data *after* it has already been loaded into the warehouse (moving data from the Silver to Gold layers).
2. **Data Modeling:** It builds Dimensional Models (Facts & Dimensions) using reusable, modular SQL.
3. **Lineage & Docs:** It automatically generates DAG dependency graphs (via the `ref()` function) and data dictionaries.
4. **Data Quality Testing:** It asserts data quality rules natively (`unique`, `not_null`, `accepted_values`).
5. **Slowly Changing Dimensions:** It natively handles SCD Type 2 tracking using the `dbt snapshot` feature.

### What dbt CANNOT (or shouldn't) do:
1. **Data Extraction/Loading:** dbt cannot connect to an external API (like Shopify) or a source database (like Oracle) to extract data. It relies on ingestion tools like Fivetran, Airbyte, or Snowpipe to land the data in the Bronze layer first.
2. **Streaming / Continuous Processing:** dbt is inherently batch-oriented. It runs when you execute `dbt run`. It cannot natively listen to an event queue and process messages continuously (which is exactly why we use Snowflake Streams and Tasks for the Bronze-to-Silver CDC layer).
3. **Infrastructure Management:** As mentioned, it shouldn't manage Warehouses, Users, Roles, or Snowpipes.
4. **Procedural Error Handling:** dbt writes set-based SQL. It cannot perform row-by-row `TRY...CATCH` exception handling to route a single bad JSON payload to a Dead Letter Queue (which is why we use Snowpark for our complex engineering pipelines).
