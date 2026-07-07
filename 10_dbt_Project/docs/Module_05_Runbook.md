# Operational Runbook: Dimension Layer

## Common Production Issues

### 1. Duplicate Business Keys (Fan-out)
**Symptom:** When a BI Analyst joins `fct_sales` to `dim_customer`, the total sales double.
**Root Cause:** The `dim_customer` table contains duplicate records for the same Business Key, causing a cartesian explosion (fan-out) during the join.
**Resolution:** 
Dimension tables must strictly guarantee uniqueness on their primary key (`customer_sk`). This is why we enforce the `unique` and `not_null` tests in the `schema.yml`. If the CI pipeline fails this test, an Analytics Engineer must debug the upstream intermediate model (`int_customers_enriched`) to apply proper deduplication or window functions (`row_number() over (partition by business_key order by updated_at desc)`) to ensure a 1:1 grain.

### 2. Broken Hierarchies
**Symptom:** A Power BI matrix visual showing Category -> Sub-Category -> Product is broken; Sub-Category shows as "Blank".
**Root Cause:** The Product hierarchy mapping in the upstream ERP system was incomplete or drifted.
**Resolution:**
Use `dbt_expectations` in the `schema.yml` to enforce `not_null` on hierarchy levels. For dimensions, always use `coalesce(sub_category, 'UNKNOWN')` to ensure BI drill-downs never break on `NULL`s.

### 3. Late Arriving Dimensions (Orphaned Facts)
**Symptom:** An order exists in `fct_sales`, but the `customer_sk` cannot be found in `dim_customer`.
**Root Cause:** The transactional order data arrived in Snowflake faster than the CRM customer data.
**Resolution:**
The Fact table must gracefully handle this by assigning a dummy `-1` Surrogate Key (or a hash of `-1`), which joins to an explicit "Unknown / Not Yet Arrived" record physically inserted into the Dimension table.
