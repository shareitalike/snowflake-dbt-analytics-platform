# Interview Notes: dbt Cloud + Airflow Integration

## Q: Why use dbt Cloud Jobs instead of executing `dbt run` locally on the Airflow worker?
**A:** "In a startup, running dbt Core directly on an Airflow Celery worker is fine. In the Enterprise, it's a massive anti-pattern. If you run `dbt run` locally, Airflow has to pull the entire dbt repository, manage the `dbt-snowflake` python dependencies, and handle the heavy compilation memory overhead. By using dbt Cloud, Airflow simply makes a lightweight API call. dbt Cloud handles the isolated compilation environment, the detailed UI logging, and the artifact hosting. Airflow remains purely an orchestrator."

## Q: How do you monitor dbt jobs and recover from failures?
**A:** "We use the `DbtCloudRunJobOperator` in Airflow. If the dbt job fails, the Operator registers the failure in Airflow, which instantly triggers our custom `enterprise_failure_callback` to ping Slack. The Data Engineer clicks the link in Slack, which routes them directly to the dbt Cloud UI to view the specific SQL error. Once they fix the model in Git, they simply click 'Clear' on the Airflow task, and Airflow re-triggers the API call."

## Q: How do you capture metadata (like rows tested or inserted) from dbt?
**A:** "We don't just trigger the job and forget it. We built a custom `EnterpriseDbtCloudClient` in Airflow that uses the dbt Cloud API to download the `run_results.json` and `manifest.json` artifacts *after* the job completes. We parse those JSON files in Airflow and push the metadata (test failures, execution times) into a centralized Snowflake observability database."

## Q: How do you handle multiple environments (Dev, QA, Prod) in Airflow and dbt?
**A:** "Hardcoding Job IDs in DAGs is a massive anti-pattern. If you hardcode `job_id=10001`, how do you test the DAG in Dev without accidentally building the Prod Medallion architecture? 
Instead, we use Airflow Variables. The DAG executes `job_id={{ var.json.my_env_variables.dbt_build_job_id }}`. 
In the Dev environment, that variable points to Job 20001 (which runs against the `DEV_DB`). In Prod, it points to Job 10001. This allows us to promote the exact same `dbt_cloud_master_dag.py` file through our CI/CD pipeline from Dev to Prod without changing a single line of Python code."

## Enterprise Best Practices Demonstrated
1. **Separation of Compute and Orchestration:** Strict enforcement of Airflow as a control plane (API caller) and dbt Cloud as the execution plane.
2. **Artifact Mining:** Demonstrating advanced usage of the dbt API by actively pulling down and parsing run artifacts for Data Quality logging.
