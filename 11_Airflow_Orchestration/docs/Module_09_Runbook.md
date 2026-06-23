# Operational Runbook: CI/CD for Airflow

## Common Production Issues

### 1. Failed Deployment (Import Errors in Prod)
**Symptom:** After a successful deployment to Prod, 15 DAGs display a red "Broken DAG: Import Error" in the Airflow UI.
**Root Cause:** A developer added `import pandas` to a DAG file, but `pandas` was not added to the `requirements.txt` file in S3. 
**Resolution:**
Our CI/CD pipeline prevents this. The `pytest test_dag_integrity.py` step in GitHub Actions attempts to compile the DAG locally on the GitHub runner. If `pandas` is missing, the CI pipeline fails *before* the code is deployed to Prod. If this still happens, verify the GitHub Runner's python environment matches the MWAA constraints.

### 2. Rollback Failure
**Symptom:** A bad DAG was pushed to Prod, causing pipeline failures. The engineer attempts to roll back but isn't sure how.
**Root Cause:** Lack of understanding of MWAA S3 sync.
**Resolution:**
Do not manually delete files from the S3 bucket. Simply hit the "Revert" button on the GitHub Pull Request. This will automatically generate a new commit restoring the previous state, which triggers the GitHub Actions pipeline to re-sync the S3 bucket via `aws s3 sync --delete`.

### 3. Missing Airflow Connection
**Symptom:** DAG fails instantly on trigger because `snowflake_default` is missing in the new QA environment.
**Root Cause:** The Terraform code didn't run to populate Secrets Manager, or the Airflow UI was wiped.
**Resolution:**
The `tests/smoke_tests.py` runs as part of the post-deployment step. It verifies that critical connections and variables exist before handing the environment over.
