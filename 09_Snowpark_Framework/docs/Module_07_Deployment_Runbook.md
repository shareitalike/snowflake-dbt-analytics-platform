# Operational Runbook: Reference Data & Lookups

## Common Production Issues

### 1. Missing Reference Data (High Fallback Volumes)
**Symptom:** 20% of ingested orders have a `STORE_REGION` equal to `UNMAPPED`.
**Root Cause:** A new store was opened, but the Master Data team has not yet updated the Store dimension table in Snowflake.
**Resolution:** 
1. The Data Quality engine will have flagged these rows in the metadata tables.
2. The Master Data team inserts the new store into the Reference Table.
3. Use the Phase 08 Replay Framework to replay the affected batch. The `DimensionResolver` will automatically apply the new mappings.

### 2. Expired Reference Values (Data Corruption)
**Symptom:** A transaction lookup fails even though the business key exists in the dimension table.
**Root Cause:** The temporal bounded join failed because the `transaction_date` occurred *after* the `Effective End Date` of the reference row, and no new `Current Flag = TRUE` row was inserted by the CDC process.
**Resolution:**
The CDC framework (Module 1-5) must be checked. Ensure that Type 2 SCD MERGE statements are correctly closing old records and inserting new ones.

### 3. Duplicate Business Keys (Cartesian Explosions)
**Symptom:** Row counts explode after a surrogate key resolution.
**Root Cause:** Overlapping `effective_start_date` and `effective_end_date` bounds in the reference table.
**Resolution:** 
The `LookupManager` automatically traps row count inflations during joins and raises a `DataQualityException` to prevent Cartesian explosions. The underlying Reference Table must be fixed to ensure contiguous, non-overlapping bounds.

### 4. Slow Lookup Performance
**Symptom:** A micro-batch takes 5 minutes to join against the Payment Methods table.
**Root Cause:** The pipeline is using the distributed `DimensionResolver` instead of the `ReferenceCache` for a table with only 15 rows.
**Resolution:**
Refactor the pipeline to use the `ReferenceCache` for this specific lookup. Ensure the `ReferenceCache` limits are not exceeded to avoid Out-Of-Memory (OOM) errors on the Snowpark nodes.
