# Operational Runbook: Sources & Seeds

## Common Production Issues

### 1. Source Freshness Failures
**Symptom:** `dbt source freshness` fails with `ERROR: source shopify.raw_orders is 14 hours old (error threshold: 12 hours)`.
**Root Cause:** The upstream CDC pipeline (Phase 8) or the API ingestion (Phase 7) has silently halted or is queueing.
**Resolution:** 
Do not blindly run the dbt DAG. If freshness fails, the underlying data is stale, and running the DAG will just generate stale Gold models. Investigate the Snowpipe/Tasks pipeline in Snowflake. Once the upstream pipeline catches up, re-run `dbt source freshness` and then execute `dbt build`.

### 2. Broken Source Contracts (Schema Drift)
**Symptom:** `dbt build` fails immediately on the `stg_shopify__orders` model because a column is missing.
**Root Cause:** The Shopify API changed its payload structure, dropping a field.
**Resolution:** 
Because we declare explicit Data Contracts in our `sources.yml` and test them using `dbt-expectations`, dbt trapped the error *before* it could pollute the data warehouse. An Analytics Engineer must either update the source YAML to reflect the new schema, or escalate to the Data Engineering team to restore the missing field.

### 3. Expired or Out-of-Sync Seeds
**Symptom:** A transaction lookup assigns a fallback value (`UNMAPPED`) because a new `Payment Method` (e.g., 'APPLE_PAY') was introduced in production, but it isn't in the dbt Seed.
**Root Cause:** The business added a payment method in the POS system without notifying the data team.
**Resolution:** 
Add 'APPLE_PAY' to `seeds/payment_methods.csv`. Commit the code and open a PR. Once merged, execute `dbt seed --select payment_methods` in production to materialize the new reference data.
