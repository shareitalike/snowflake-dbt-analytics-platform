# Phase 10 - Module 10: Enterprise Macros & Reusable Components Framework

This module completes the Phase 10 dbt implementation by abstracting our most heavily used SQL snippets into reusable Jinja functions. This enforces the DRY principle and allows our entire data warehouse to inherit business rule changes from a single, centralized codebase.

## Deliverables Checklist

- [x] **Repository Structure:** Placed models in `macros/utilities/`, `macros/audit/`, and `macros/dates/`.
- [x] **Utility Macros (`safe_cast.sql`):** Created a robust macro that natively compiles into Snowflake's `try_cast()`. This prevents pipeline crashes from rogue string data infiltrating numeric columns.
- [x] **Audit Macros (`generate_audit_columns.sql`):** Created a macro that injects standard `dbt_updated_at`, `dbt_invocation_id`, and `dbt_git_commit` metadata into every table. This provides exact row-level lineage tracing back to the specific GitHub commit that executed the dbt run.
- [x] **Date Macros (`convert_timezone.sql`):** Abstracted timezone logic, demonstrating the `adapter.dispatch` concept by compiling differently depending on whether the target warehouse is Snowflake or Postgres.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_10_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/10_dbt_Project/docs/Module_10_Runbook.md).md) detailing how to manage Macro Recursion (Infinite Loops) and Compilation Scope Errors.

## Usage Example (Jinja Macro)
```sql
select
    {{ safe_cast('quantity', 'integer') }} as qoh,
    {{ convert_timezone('created_at_utc', 'UTC', 'America/New_York') }} as created_at_est,
    {{ generate_audit_columns() }}
from source
```
