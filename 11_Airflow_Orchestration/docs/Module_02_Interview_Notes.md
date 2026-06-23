# Interview Notes: Airflow Infrastructure

## Q: How do you deploy and scale Airflow in production?
**A:** "We do not run Airflow on a single EC2 instance. We use a distributed architecture like Managed Workflows for Apache Airflow (MWAA) or Astronomer, which uses a Celery or Kubernetes executor. This allows the Scheduler to sit on a separate node from the Workers. If we have a massive burst of tasks, the worker nodes auto-scale horizontally. The Metadata DB is hosted on an isolated, Multi-AZ AWS RDS Postgres instance."

## Q: How do you manage secrets and connections in Airflow?
**A:** "We never store passwords in the Airflow UI or `connections.json` in production. We configure the Airflow Secrets Backend to point to AWS Secrets Manager. This satisfies our SOC2 compliance requirements, allows the InfoSec team to rotate keys dynamically, and prevents credential leaks if the Airflow Postgres database is ever compromised."

## Q: How do you handle configuration drift between environments?
**A:** "We use Docker to guarantee environment parity. Developers run `docker-compose up` locally, which pulls the exact same `apache/airflow` Docker image and `requirements.txt` used in production. We manage environment-specific variables (like `s3_bronze_bucket`) using Airflow Variables loaded dynamically via JSON, ensuring the DAG code itself remains 100% environment agnostic."

## Enterprise Best Practices Demonstrated
1. **Triggerer Integration:** Explicitly calling out the Triggerer component (introduced in 2.2) to support Async/Deferrable operators, saving massive compute costs on long Snowflake queries.
2. **External Secrets Backend:** Architecting secure connection management rather than hardcoding.
