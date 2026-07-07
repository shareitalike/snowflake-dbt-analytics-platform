# Phase 10 - Module 9: Enterprise Generic & Custom Tests Framework

This module establishes our CI/CD Data Quality gates. We utilize a combination of generic macros, complex singular tests, and external packages to rigorously enforce Data Contracts before bad data can pollute the Executive BI layer.

## Deliverables Checklist

- [x] **Repository Structure:** Test files structured in `tests/generic/` and `tests/singular/`.
- [x] **Package Integration:** Configured `dbt_expectations` to run advanced bounds testing and regex validation.
- [x] **Generic Tests:** Implemented the reusable `test_is_positive.sql` macro, applied to Fact tables to ensure metrics like `net_revenue` never drop below zero.
- [x] **Singular Tests:** Implemented `assert_revenue_reconciliation.sql`. This complex, multi-table query asserts that the sum of `fct_sales.net_revenue + tax` exactly matches the raw source data in `stg_orders`, guaranteeing zero data loss (fan-outs/orphans) during the ETL process.
- [x] **Failure Handling (Severity):** Configured `tests/schema.yml` to utilize `severity: error` for critical financial checks (halting the CI pipeline) and `severity: warn` for non-critical PII issues like malformed emails (logging the error but allowing the pipeline to proceed).
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_09_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_09_Runbook.md).md) detailing CI/CD pipeline integration and debugging schema drift.

## Usage Example (Executing Tests)
```bash
# Run all tests, halting on errors but continuing on warnings
dbt test --target dev
```
