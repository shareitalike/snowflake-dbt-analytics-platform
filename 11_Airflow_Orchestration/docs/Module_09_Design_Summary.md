# Enterprise CI/CD for Apache Airflow
## Module 09 - Design Summary

### Git Workflow and Branching Strategy
We employ a robust GitHub Flow tailored for Airflow on AWS MWAA.
- **Feature Branches:** Developers create `feature/xyz` branches to modify DAGs or SQL. Pushing to GitHub triggers the CI Pipeline (Black, Flake8, Pylint, Safety, Pytest).
- **Develop Branch:** Merging to `develop` automatically deploys the DAGs via AWS CLI (`aws s3 sync`) to the Development MWAA environment. Smoke tests run immediately to ensure the `dev_variables` exist.
- **Main Branch:** Merging to `main` requires an approval gate. Once approved, the GitHub Action deploys the DAGs to the Production MWAA bucket.

### Static Analysis and Dependency Checking
Because Airflow DAGs execute globally in the scheduler every 30 seconds, a bad import or top-level database call will crash the entire platform. 
Our GitHub Actions pipeline utilizes `pylint` to perform static analysis on DAG files, specifically looking for heavy top-level code. Furthermore, the `safety` package checks the `requirements.txt` file for known vulnerabilities (CVEs) before any deployment is authorized.

### Environment Promotion
Hardcoding is prohibited. A single Python DAG file (`dbt_cloud_master_dag.py`) is written once and promoted linearly: `Dev -> QA -> Prod`. The environment behavior changes dynamically because the DAG pulls from `{{ var.json.my_variables }}` instead of relying on hardcoded Job IDs or Warehouse names.
