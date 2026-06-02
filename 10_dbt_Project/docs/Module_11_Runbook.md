# Operational Runbook: Documentation Framework

## Common Production Issues

### 1. Broken Exposures (Dashboard Failures)
**Symptom:** A Power BI refresh fails with `Column 'customer_segment' not found in TB_CUSTOMER_DIM`.
**Root Cause:** An engineer deleted the column from the dbt model, completely unaware that a downstream dashboard relied on it, because no `exposure` was defined in dbt.
**Resolution:** 
Mandate that ALL tier-1 BI dashboards must be mapped as dbt Exposures. Engineers must run `dbt build -s +exposure:exec_dashboard` to verify that their upstream code changes will not break the downstream consumer.

### 2. Outdated Business Definitions
**Symptom:** The data catalog defines `Active Customer` as "purchased within 30 days," but the business updated the definition to "90 days" last year.
**Root Cause:** Definitions were hardcoded across dozens of `schema.yml` files, making it impossible to keep them synchronized with the business.
**Resolution:**
Migrate all definitions to the `catalog/business_glossary.md` using `docs` blocks. Assign a strict "Data Owner" (e.g., `@finance_team`) to the `schema.yml` meta block so engineers know exactly who to Slack for definition approvals.

### 3. PII / Sensitivity Leaks
**Symptom:** A data scientist accidentally queries plaintext SSNs because the column wasn't masked.
**Root Cause:** The data was not classified in the catalog.
**Resolution:**
Enforce strict `meta` tagging in `schema.yml`. Every column containing PII must have `meta: { sensitivity: 'high', pii: true }`. This metadata can be consumed by Snowflake's Dynamic Data Masking policies (Phase 6) to automatically redact the column for non-privileged roles.
