# Operational Runbook: Testing Framework

## Common Production Issues

### 1. Failing Relationships (Orphaned Facts)
**Symptom:** `dbt test` fails with: `Failure in test relationships_fct_sales_customer_sk__customer_sk__dim_customer`.
**Root Cause:** A `customer_sk` exists in `fct_sales`, but that surrogate key does not exist in `dim_customer`. This is a strict referential integrity violation.
**Resolution:** 
Investigate the CDC pipeline. Did the Customer pipeline fail to run before the Sales pipeline? In our architecture, we mitigate this by defaulting unknown keys to `-1` (the UNKNOWN dimension record). If this test still fails, it means the `-1` record was accidentally deleted from the dimension table.

### 2. Schema Drift Breaking Tests
**Symptom:** `dbt test` fails with `column 'is_active' does not exist`.
**Root Cause:** The upstream source (e.g., Salesforce) renamed `is_active` to `status_active`, breaking the Staging layer and all downstream tests.
**Resolution:**
The `error` severity correctly stopped this from silently polluting the warehouse. An Analytics Engineer must update the `stg_` model to map `status_active` back to the standardized `is_active` alias, restoring the Data Contract.

### 3. Invalid Business Rules (Negative Revenue)
**Symptom:** The singular test `assert_revenue_is_positive` fails, highlighting 50 records in `fct_sales`.
**Root Cause:** A bug in the POS system recorded a "discount" as a massive negative number that exceeded the total price, resulting in a negative net revenue calculation.
**Resolution:**
The pipeline halts. The Data Engineering team must coordinate with the POS software engineers to fix the root cause. In the interim, update `int_orders_enriched` to use `greatest(0, (total_price_usd - discount_amount))` to aggressively sanitize the bad data.
