# Phase 11: Enterprise Apache Airflow Orchestration

This directory establishes the overarching "Control Plane" of the OmniRetail Data Platform. Apache Airflow orchestrates our heterogeneous systems (AWS, Snowflake, Snowpark, dbt) into a cohesive, idempotent Directed Acyclic Graph (DAG).

## Deliverables Checklist

- [x] **Repository Structure:** Generated the standard `dags/`, `plugins/`, `operators/`, and `config/` scaffolding.
- [x] **Architecture Design:** Authored [01_Architecture_Design.md](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/01_Architecture_Design.md), mapping the exact lineage from external S3 Sensors to downstream Power BI triggers.
- [x] **Coding Standards:** Authored [02_Standards_and_Guidelines.md](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/02_Standards_and_Guidelines.md) to enforce stateless, idempotent DAG design and prevent "Spaghetti" code.
- [x] **Operational Runbook:** Authored [03_Operational_Runbook.md](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/03_Operational_Runbook.md), detailing how to debug "Zombie Tasks" and why XCom should never be used to pass large datasets.

## Airflow as Code
Because Airflow DAGs are written in Python, they are treated with the exact same Software Engineering rigor as our Snowpark pipelines:
- Linted via `flake8` and `black`.
- Tested via `pytest`.
- Deployed automatically via GitHub Actions (CI/CD).
