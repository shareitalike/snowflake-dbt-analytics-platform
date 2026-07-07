# Phase 11 - Module 9: Enterprise CI/CD for Apache Airflow

This module introduces a highly resilient CI/CD pipeline using GitHub Actions, ensuring that no broken DAG, circular dependency, or vulnerable python package ever reaches the Airflow Scheduler.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `.github/workflows/`, `scripts/ci_cd/`, and `tests/`.
- [x] **GitHub Actions Pipeline (`airflow_ci_cd.yml`):** Implemented a multi-stage pipeline handling Code Validation (Black/Flake8), Static Analysis (Pylint), Dependency Checking (Safety), and Automated Pytest validation.
- [x] **DAG Integrity Tests (`test_dag_integrity.py`):** A dynamic testing suite that programmatically imports every DAG, asserts there are no cyclic dependencies, and enforces that all DAGs contain enterprise tags and owner metadata.
- [x] **Automated Smoke Tests (`smoke_tests.py`):** Checks the Airflow ORM post-deployment to guarantee that mandatory connections (`snowflake_default`) and variables exist in the target environment.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_09_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/11_Airflow_Orchestration/docs/Module_09_Runbook.md).md) detailing environment promotion and rollback strategies via AWS MWAA S3 syncing.

## Usage Example (Local DAG Validation)
Before committing your code, a Data Engineer can run the exact validation suite the CI pipeline uses:
```bash
export PYTHONPATH=$PYTHONPATH:$(pwd)/11_Airflow_Orchestration
pytest 11_Airflow_Orchestration/tests/test_dag_integrity.py -v
```
If the test passes locally, it is guaranteed to parse correctly in Airflow.
