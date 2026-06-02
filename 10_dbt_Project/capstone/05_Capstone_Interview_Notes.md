# Capstone Interview Notes: End-to-End Architecture Defense

## Q: Walk me through your complete project architecture.
**A:** "At OmniRetail, we built a Medallion Architecture on Snowflake. 
- **Bronze (Ingestion):** We used Fivetran and HVR to replicate raw JSON APIs (Shopify) and relational ERP data (Oracle) into Snowflake. 
- **Silver (Transformation):** We used dbt for heavy lifting. We built a Staging layer to cast and standardize, an Intermediate layer to generate Surrogate Keys and handle complex joins, and we leveraged custom dbt Macros to inject Git audit metadata. 
- **Gold (Serving):** We built highly optimized Kimball dimensional models. We used dbt Snapshots for SCD Type 2 tracking on Dimensions, and `MERGE` / `INSERT_OVERWRITE` incremental models for Fact tables clustered by Date.
Finally, we wrapped it all in dbt Data Contracts and generic testing to guarantee Data Quality before it hit Power BI."

## Q: Why Snowflake?
**A:** "Snowflake separates storage from compute. This allowed us to ingest terabytes of raw data cheaply, while simultaneously spinning up an isolated `XLARGE` warehouse for dbt transformations and a dedicated `MEDIUM` warehouse for Power BI. They don't fight for resources, so our executive dashboards never lag."

## Q: Why dbt over traditional Stored Procedures?
**A:** "Software engineering rigor. Stored Procedures are opaque, hard to version control, and lack native testing. dbt allowed us to write modular `SELECT` statements, automatically generated our DAG, enforced CI/CD through GitHub, and generated a Data Catalog out of the box. It turned Data Engineering into Analytics Engineering."

## Q: How does CDC integrate with dbt?
**A:** "Fivetran/HVR push raw updates to Snowflake. We used Snowflake Streams & Tasks to capture the precise `inserted_at` metadata. In dbt, instead of just using `current_date()`, we built a custom Jinja macro that dynamically reads that CDC watermark. This allowed our incremental models to gracefully catch Late Arriving Data without doing full table scans."

## Q: How do you optimize cost in this architecture?
**A:** "Two main ways:
1. **Incremental Models & Clustering:** By clustering `fct_sales` by `date_sk` and using incremental merges, we avoid scanning billions of historical rows every hour.
2. **Slim CI:** When testing PRs in GitHub Actions, we use dbt's `--defer` state. We only rebuild the single model that changed, rather than rebuilding the entire warehouse just to test one line of code."

## Q: How do you monitor the platform?
**A:** "We enforce strict `severity: error` data tests on Primary Keys. If a test fails, it halts the Airflow DAG and pages the Data Engineering team. For non-critical issues (like a malformed email address), we use `severity: warn` and push those logs to a centralized Data Quality Dashboard for the business owners to remediate."
