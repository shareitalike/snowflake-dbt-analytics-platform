# Enterprise Production Readiness & Runbook

Before the OmniRetail Data Platform is officially handed over to the business, the following checks must be validated.

## Production Readiness Checklist
- [ ] **Data Contracts:** All Tier-1 Gold models (`fct_sales`, `dim_customer`) have `contract: {enforced: true}` configured to prevent breaking schema drift.
- [ ] **Role-Based Access Control (RBAC):** Snowflake Dynamic Data Masking is actively reading the `meta: {contains_pii: true}` tags from dbt to mask SSNs and Emails from non-privileged BI users.
- [ ] **Orchestration:** Airflow / dbt Cloud job is scheduled, and `dbt source freshness` is strictly enforced before model execution begins.
- [ ] **Slim CI:** GitHub Actions are configured to use `--defer --state` on Pull Requests to prevent full-warehouse rebuilds during code reviews.

## UAT (User Acceptance Testing) Checklist
- [ ] **Revenue Reconciliation:** Finance has signed off that `net_revenue` in `fct_sales` matches the legacy Oracle ERP system to the penny.
- [ ] **Dashboard Validation:** Power BI Executive Dashboard refreshes successfully against the new Snowflake backend without modifying front-end DAX code.
- [ ] **Data Catalog Access:** Business users have access to `dbt docs` and can read the Business Glossary for metrics like GMV and CAC.

## Disaster Recovery & Rollback Runbook

### Scenario A: Corrupted Incremental Load
*A bug in the POS system sent a batch of massive negative discounts, corrupting the incremental `fct_sales` table.*
1. **Halt the Pipeline:** Pause the Airflow DAG.
2. **Revert the Code:** If the bug was introduced via a recent dbt PR, revert it in GitHub.
3. **Full Refresh:** Manually trigger the Airflow job with `dbt build --select fct_sales+ --full-refresh`. This will drop the corrupted Snowflake table and completely rebuild history using the pristine Raw Bronze data.

### Scenario B: Snowflake Region Outage
*AWS US-East-1 goes completely offline, taking down our primary Snowflake deployment.*
1. **Failover:** Execute Snowflake's native Account Replication failover to US-West-2.
2. **Redirect BI:** Update Power BI connection strings to point to the US-West-2 Snowflake URL.
3. **Resume Operations:** Because our dbt code is version-controlled in GitHub and entirely stateless, we do not lose any transformation logic. Once the secondary region is active, Airflow simply resumes running `dbt build` against the secondary Snowflake instance.
