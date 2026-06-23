# Interview Mastery: Apache Airflow (Enterprise Orchestration)

If you are interviewing for a Senior Data Engineer or Principal Architect role, Airflow is often the deciding factor. Use these answers to prove you know how to build platforms, not just scripts.

## Q: Walk me through your Airflow platform.
**A:** "In my architecture, Airflow is the Control Plane (the Brain), not the Execution Plane (the Muscle). Airflow holds zero data and performs zero heavy compute. I orchestrated a massive Medallion architecture where Airflow triggers AWS S3 validations, checks Snowflake CDC Streams via custom sensors, triggers Snowpark for complex Python flattening, and then makes an API call to dbt Cloud to build the core data models. The entire platform is monitored via StatsD pushing metrics to Prometheus and Grafana."

## Q: How does Airflow orchestrate dbt Cloud?
**A:** "A massive anti-pattern is running `dbt run` locally on an Airflow Celery worker. That causes Python dependency conflicts (`dbt-snowflake` vs `apache-airflow`) and memory crashes. Instead, I use the `DbtCloudRunJobOperator` in `deferrable` mode. Airflow makes a lightweight REST API call to dbt Cloud, which handles the heavy SQL compilation on its own isolated infrastructure. When dbt finishes, my custom Airflow API client pulls the `run_results.json` artifact so I can log exact row counts and Data Quality test failures."

## Q: How do you avoid duplicate DAG code?
**A:** "I use a Metadata-Driven Pipeline Registry. I don't let engineers copy-paste Python files. They define the pipeline (Source, Target, SLA, Snowflake Warehouse, Owner) in a YAML file. I built a Dynamic DAG Factory in Python that parses that YAML file on the fly and generates all the DAGs and TaskGroups in memory. If a new business unit needs a pipeline, they just submit a PR adding 10 lines to the YAML file."

## Q: How do you manage SLAs and reduce Alert Fatigue?
**A:** "I separate engineering failures from business failures. If a task fails, that's an engineering problem. My intelligent alert router parses the DAG's tags—if it's `tier:1`, it hits PagerDuty; if it's `tier:3`, it just drops a message in Slack. On the other hand, if a DAG runs too long and misses its delivery time (e.g., 8:00 AM), that's a business problem. I use Airflow's native SLA parameter which triggers an escalation matrix directly to the Business Operations team."

## Q: How do you deploy and validate Airflow code?
**A:** "I use a strict GitOps CI/CD pipeline via GitHub Actions. When code is pushed, the pipeline runs Pylint to block heavy top-level compute, `safety` to block CVE vulnerabilities, and Pytest. The Pytest suite actively compiles the DAGs locally (`dag.test_cycle()`) to catch cyclic dependencies and import errors *before* deployment. Once validated, the pipeline syncs the DAGs to an AWS S3 bucket for MWAA, and then runs automated smoke tests to verify connections exist in the target environment."
