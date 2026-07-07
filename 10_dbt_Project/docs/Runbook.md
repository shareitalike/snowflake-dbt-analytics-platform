# Operational Runbook: Enterprise dbt

## Git, Slim CI, and Deployment Strategy

### Git Workflow
We enforce a strict Trunk-Based Development model:
1. **Feature Branch:** Analytics Engineers create branches (e.g., `feat/add-gmv-metric`) off `main`.
2. **Pull Request (PR):** When code is committed, a PR is opened. This triggers dbt Cloud's **Slim CI** pipeline.
3. **Main:** Once approved, code is merged into `main`, which triggers the Production deployment.

### Slim CI Strategy
Running the entire dbt project on every Pull Request takes too long and wastes Snowflake credits. Slim CI leverages dbt's `state:modified` selector to dynamically identify which models were changed, and only runs/tests those models *and their first-degree downstream dependents*.
Command: `dbt build --select state:modified+1 --defer --state path/to/prod/artifacts`

### Common Production Issues

#### 1. Long-Running Incremental Models (Performance Degradation)
**Symptom:** A fact table that normally takes 2 minutes is now taking 45 minutes.
**Root Cause:** The `is_incremental()` logic is missing a strict cluster key filter on the source data, causing a full table scan of the raw data on every micro-batch.
**Resolution:** 
Ensure the incremental macro filters the source data dynamically: `where ingested_at > (select max(ingested_at) from {{ this }})`. Ensure the target table is clustered by the merge key.

#### 2. Test Failure on Deployment (Unique/Not Null)
**Symptom:** The production pipeline halts because a `unique` test failed on `dim_customers`.
**Root Cause:** Upstream source data introduced duplicates.
**Resolution:** 
Because we test *before* exposing to BI tools (using `dbt build`), the bad data did not reach the Gold layer. Analytics Engineers must add a deduplication macro (e.g., `dbt_utils.deduplicate`) to the intermediate model, push the fix via PR, and let Slim CI validate it before merging.

#### 3. Ephemeral CTE Bloat (Compilation Error)
**Symptom:** Snowflake returns a "query too complex" error.
**Root Cause:** Using `ephemeral` materialization on highly complex intermediate models results in 500-line CTEs being injected into the final query, breaking the Snowflake query compiler.
**Resolution:** 
Change the `intermediate` model materialization from `ephemeral` to `view` or `table` to force Snowflake to materialize intermediate steps, breaking up the compilation graph.
