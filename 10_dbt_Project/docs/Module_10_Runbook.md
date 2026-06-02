# Operational Runbook: Macros Framework

## Common Production Issues

### 1. Macro Recursion (Infinite Loops)
**Symptom:** `dbt run` hangs indefinitely during the compilation phase, or throws a `maximum recursion depth exceeded` error.
**Root Cause:** A macro calls another macro, which calls the first macro back (e.g., `macro_A` -> `macro_B` -> `macro_A`). 
**Resolution:** 
Jinja does not have sophisticated cycle detection. Analytics Engineers must strictly map macro dependencies. A utility macro (like `safe_cast`) should NEVER call a business macro. 

### 2. Compilation Errors (Incorrect Variable Scope)
**Symptom:** `dbt compile` fails with `undefined variable 'column_name'`.
**Root Cause:** A developer tried to pass a SQL column name into a Jinja `if` statement.
**Resolution:**
Jinja executes *before* Snowflake executes the SQL. Jinja has no idea what data is inside the Snowflake tables. You cannot write `{% if column_name == 'VIP' %}` because `column_name` is just a text string to Jinja. Jinja is purely for text replacement. To evaluate row-level data, the macro must compile a SQL `CASE WHEN` statement.

### 3. Reusable Logic Issues (Cross-Database Incompatibility)
**Symptom:** The project migrates from Postgres to Snowflake, and the `convert_timezone` macro fails.
**Root Cause:** The macro was hardcoded with Postgres-specific `AT TIME ZONE` syntax instead of using the `adapter.dispatch` pattern.
**Resolution:**
When writing utility macros, use dbt's native `adapter.dispatch` pattern to provide different SQL compilations depending on the target database (e.g., overriding the macro specifically for `snowflake` vs `redshift`).
