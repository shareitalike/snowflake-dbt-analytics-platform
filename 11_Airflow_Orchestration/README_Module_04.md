# Phase 11 - Module 4: Enterprise Snowflake Operators & Hooks

This module bridges the gap between Apache Airflow's orchestration engine and Snowflake's compute engine. By extending the native Airflow Snowflake providers, we enforce enterprise-wide Data Governance, Cost Optimization, and Operational Stability directly into the codebase.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `operators/` and `hooks/`.
- [x] **Enterprise Custom Hooks (`enterprise_snowflake_hook.py`):** Extended the native `SnowflakeHook` to include DBA-level commands, such as `validate_warehouse_health()` and `monitor_warehouse_credits()`.
- [x] **Enterprise Custom Operators (`enterprise_snowflake_operator.py`):** Extended the native `SnowflakeOperator`. Added strict exception handling (`ROLLBACK;` on failure) and dynamic CDC Stream checks (`check_stream_has_data()`) to prevent executing massive SQL queries on empty data streams.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_04_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_04_Runbook.md).md) detailing why extending native providers is a hallmark of Principal-level data engineering.

## Usage Example (In an Airflow DAG)
```python
from operators.snowflake.enterprise_snowflake_operator import EnterpriseSnowflakeOperator

run_incremental_load = EnterpriseSnowflakeOperator(
    task_id='run_incremental_load',
    snowflake_conn_id='snowflake_default',
    sql="MERGE INTO fct_sales ...",
    stream_to_check='sales_stream',     # Custom argument: Checks if stream has data first
    require_warehouse_resume=True,      # Custom argument: Resumes warehouse automatically
    autocommit=False                    # Custom argument: Wraps query in BEGIN/COMMIT
)
```
