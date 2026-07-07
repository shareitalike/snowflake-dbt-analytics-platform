# Enterprise Airflow Infrastructure & Configuration
## Module 02 - Design Summary

### Airflow Deployment Architecture
To manage enterprise-scale workloads reliably, we utilize a distributed architecture (e.g., Celery Executor or Kubernetes Executor).
- **Webserver:** The UI layer. Stateless. Can be scaled horizontally.
- **Scheduler:** The heart of Airflow. Evaluates DAGs and sends Tasks to the execution queue.
- **Triggerer:** A specialized component introduced in Airflow 2.2 for running *Deferrable Operators* (async operations). This is critical for connecting to Snowflake, allowing Airflow to check query status without tying up a worker thread for 4 hours.
- **Workers:** The nodes that actually execute the Python code. We scale these horizontally based on queue depth.
- **Metadata Database (Postgres):** Stores all state, XComs, and history.

### Secrets Management Strategy
Airflow native connections store passwords in the Postgres Metastore (encrypted via Fernet key). However, enterprise security (SOC2 compliance) dictates that credentials must be rotatable and centrally managed.
We configured the `airflow.cfg` to point the **Secrets Backend** to **AWS Secrets Manager**. When a DAG requests the `snowflake_default` connection, the Airflow scheduler fetches it live from AWS. This means the DB Admins can rotate the Snowflake password daily, and Airflow never skips a beat.

### High Availability & Backups
- The Metadata Postgres DB must be deployed on AWS RDS Multi-AZ.
- `pg_dump` backups are taken daily.
- If the Webserver goes down, the Scheduler continues executing DAGs normally.
- If the Scheduler goes down, High Availability (HA) allows a standby scheduler to immediately pick up the locks.
