# Weekly and Monthly Maintenance Schedules

## Weekly Maintenance 
**Owner:** Platform Engineer / Lead Data Engineer  
**Execution Time:** Friday afternoon

### 1. Warehouse Optimization & Query Review
- Run the [Top Expensive Queries](../../cost_optimization/monitoring/finops_dashboard_queries.sql) script.
- Identify any query scanning >90% of partitions on a large table.
- Create Jira tickets to evaluate Adding Clustering Keys or refactoring the SQL.

### 2. Resource Monitor Review
- Check current utilization vs quota.
- Adjust notification thresholds if we are tracking to hit 100% before month-end.

### 3. Unused Object Cleanup (Staging/Transient)
- Verify `TRANSIENT` staging tables are not accumulating bloat.
- (Gold tables are managed by dbt and do not need manual cleanup).

---

## Monthly Maintenance
**Owner:** Principal Architect / Operations Manager  
**Execution Time:** First week of the month

### 1. Cost Analysis & Capacity Planning
- Run the [Monthly FinOps Report](../../cost_optimization/reports/case_study_05_monthly_finops_report.md) generation.
- Compare Month-over-Month (MoM) credit consumption.
- If storage costs increased > 10%, review Time Travel retention policies.

### 2. Security & Access Review
- Query `SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS` to audit recent role assignments.
- Ensure no users have direct assignments to `SYSADMIN` or `SECURITYADMIN`.
- Identify dormant users (no login in 90 days) via `LOGIN_HISTORY` and disable them.

### 3. Disaster Recovery Validation
- Execute one of the quarterly [DR Drills](../../disaster_recovery/testing/dr_testing_plan.md).
- Document RTO/RPO achieved vs target.

### 4. Documentation & Runbook Review
- Review this document and the `daily_sop.md`.
- Ensure all runbooks reflect current architecture (e.g., if a new warehouse was added, add it to the checks).
