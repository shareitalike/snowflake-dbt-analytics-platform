# Phase 11 - Module 7: Enterprise Dynamic DAGs & TaskGroups

This module eliminates code duplication by introducing Metadata-Driven Orchestration. Instead of writing dozens of identical Python DAG files, we created a single Factory that dynamically loops over a YAML configuration file to generate all domain pipelines in memory.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `dynamic_dags/` and `taskgroups/`.
- [x] **TaskGroups (`standard_ingestion_tg.py`):** Abstracted the complex multi-step CDC logic (check stream -> trigger task -> update watermark) into a reusable UI component that can be injected anywhere.
- [x] **Metadata Configuration (`domain_config.yaml`):** The YAML file acting as the single source of truth for all domain pipelines, defining retries, schedules, and specific CDC streams to process.
- [x] **Dynamic Factory (`dag_factory.py`):** The Python engine that parses the YAML, dynamically instantiates DAG objects into the global namespace, and wires up TaskGroups in parallel for massive horizontal scaling.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_07_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_07_Runbook.md).md) detailing why protecting the Airflow Scheduler from heavy compute is critical when building dynamic factories.

## Usage Example (Adding a New Pipeline)
To add a brand new pipeline for the HR department, you do **not** write Python. You simply append this to `domain_config.yaml`:
```yaml
  - domain_name: "hr"
    owner: "data_eng_hr"
    schedule_interval: "@daily"
    retries: 2
    tags: ["domain:hr"]
    streams_to_process:
      - stream_name: "employee_stream"
        task_name: "task_process_employee"
```
The Airflow Scheduler will parse the YAML and automatically create a highly resilient DAG with the correct TaskGroups, sensors, and alerting callbacks.
