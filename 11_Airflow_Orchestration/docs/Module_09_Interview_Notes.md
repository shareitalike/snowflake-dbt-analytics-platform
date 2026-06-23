# Interview Notes: CI/CD for Apache Airflow

## Q: How do you validate DAGs before deployment?
**A:** "A broken DAG file can crash the Airflow Scheduler. Therefore, I built a rigid CI pipeline in GitHub Actions. Before any DAG merges to `develop`, the pipeline runs Black and Flake8 for styling, Pylint for static analysis to ensure there is no top-level compute, and finally Pytest. The Pytest script loops through every Python file in the `dags/` folder, actively compiles it (`dag.test()`), checks for cyclic dependencies, and verifies that mandatory tags and owners are assigned. If any step fails, the merge is blocked."

## Q: How do you roll back a failed deployment in Airflow?
**A:** "If you are using AWS MWAA, Airflow reads DAGs from an S3 bucket. My deployment strategy uses `aws s3 sync --delete` executed by GitHub Actions. If a deployment fails in production, I simply revert the PR in GitHub. The pipeline immediately syncs the previous master state back to S3, automatically wiping out the bad files. I never touch the S3 bucket manually."

## Q: What are Automated Smoke Tests in Airflow?
**A:** "A DAG might compile perfectly in CI, but fail at runtime because the `snowflake_prod` connection doesn't exist in the new environment. I wrote a `smoke_tests.py` script that hits the Airflow ORM (`from airflow.models import Connection`) immediately after deployment. It asserts that every required connection and variable exists. If the smoke test fails, the deployment is marked degraded."

## Enterprise Best Practices Demonstrated
1. **Dependency Checking:** Using `safety check` in CI to ensure Python packages in `requirements.txt` don't have known CVE vulnerabilities.
2. **Shift-Left Testing:** Catching Airflow Import Errors in GitHub Actions rather than letting them hit the Production Airflow UI.
