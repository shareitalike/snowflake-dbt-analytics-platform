# Phase 11 - Module 5: Enterprise Sensors & Event-Driven Pipelines

This module transitions our platform from rigid, time-based schedules to dynamic, Event-Driven Orchestration. By leveraging Airflow Sensors, pipelines execute the exact moment their dependencies are met, optimizing SLA delivery times and reducing compute waste.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `sensors/` and `callbacks/`.
- [x] **Enterprise Custom Sensors:** 
  - `enterprise_stream_sensor.py`: Efficiently monitors Snowflake CDC streams.
  - `enterprise_task_sensor.py`: Monitors asynchronous Snowflake `EXECUTE TASK` commands.
- [x] **Enterprise Callbacks (`enterprise_callbacks.py`):** Centralized Slack alerting system for DAG lifecycle events (`on_failure`, `on_success`, `sla_miss`).
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_05_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_05_Runbook.md).md) detailing the critical distinction between `poke` and `reschedule` modes.

## Usage Example (In an Airflow DAG)
```python
from sensors.snowflake.enterprise_stream_sensor import EnterpriseStreamSensor
from callbacks.enterprise_callbacks import enterprise_failure_callback

default_args = {
    'on_failure_callback': enterprise_failure_callback
}

wait_for_cdc_data = EnterpriseStreamSensor(
    task_id='wait_for_sales_stream',
    stream_name='sales_stream',
    snowflake_conn_id='snowflake_default'
)
```
