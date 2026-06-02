# Operational Runbook: Staging Layer

## Common Production Issues

### 1. Duplicate Source Records
**Symptom:** The `unique` dbt test fails on `stg_orders` during the CI/CD pipeline.
**Root Cause:** A source API retried a payload twice, leading to two identical records in the Bronze raw tables.
**Resolution:** 
Because we do not want duplicates entering the Gold layer, we use dbt's `dbt_utils.deduplicate` macro directly inside the staging model (partitioned by the primary key, ordered by the CDC `metadata_inserted_at` timestamp). This acts as a defensive shield, isolating the duplication error in the Silver layer.

### 2. Timezone Mismatch
**Symptom:** Revenue reported in the Gold layer is shifted by 5 hours compared to the legacy system.
**Root Cause:** The Shopify API sends timestamps in UTC, while the legacy Oracle ERP sends timestamps in EST. Downstream facts are joining them naively.
**Resolution:**
The Staging layer is responsible for normalizing timezones. Ensure the `stg_oracle_inventory` model uses Snowflake's `CONVERT_TIMEZONE('America/New_York', 'UTC', created_at)` function. All dates exiting Staging must be UTC.

### 3. Unexpected Nulls
**Symptom:** The `not_null` dbt test fails on `customer_id` in `stg_orders`.
**Root Cause:** The source system allowed a guest checkout without a customer ID, which violates our Enterprise Data Model constraint.
**Resolution:**
Instead of crashing the pipeline, staging models can utilize `coalesce(customer_id, '-1')` to assign an orphaned ID. However, this is dangerous if it masks a larger upstream issue. Review the specific test output. If it's expected behavior for Guest checkouts, change the test constraint. If it's unexpected corruption, escalate to the upstream software engineers.
