# Executive Interview Notes: Platform Capstone

## Walk me through your complete enterprise platform.
"I architected a modern, cloud-native enterprise data platform for OmniRetail using Snowflake, AWS, dbt Cloud, and Airflow. It operates on a strict T-ELT architecture. Data lands in AWS S3 and is auto-ingested into Snowflake's Bronze layer via Snowpipe. We use Snowflake Streams and Tasks for near-real-time CDC, merging that data into the Silver layer. From there, dbt Cloud takes over, transforming the data through dimensional modeling into the Gold layer, ready for Power BI. The entire platform—infrastructure and pipelines—is orchestrated by Apache Airflow and deployed via GitHub Actions and Terraform, adhering to strict FinOps and Zero-Trust security principles."

## What architectural decisions did you make?
1. **Airflow as the Brain, not the Muscle:** Airflow only orchestrates; all heavy lifting compute happens in Snowflake.
2. **Decoupled Compute:** I isolated workloads in Snowflake by creating dedicated virtual warehouses (Ingest, Transform, BI) to prevent resource contention.
3. **Infrastructure as Code (IaC):** 100% of the platform (AWS resources, Snowflake RBAC) is defined in Terraform. No manual 'ClickOps' are allowed in production.
4. **Push-based CI/CD:** We use GitHub Actions with AWS OIDC to eliminate long-lived cloud credentials.

## Why AWS? Why Snowflake? Why dbt Cloud? Why Airflow? Why Terraform?
* **AWS:** The undisputed leader in scalable, durable cloud infrastructure. S3 is perfect for our raw data lake, and IAM/Secrets Manager provides enterprise-grade security.
* **Snowflake:** Its separation of compute and storage allows us to scale workloads independently. Features like Time Travel, Zero-Copy Clones, and Snowpipe drastically simplified our architecture.
* **dbt Cloud:** It brought software engineering best practices (version control, automated testing, CI/CD) to data analytics, replacing messy stored procedures with modular, testable SQL.
* **Airflow:** It is the industry standard for programmatic DAG orchestration, providing a single pane of glass for monitoring complex dependencies across disparate systems.
* **Terraform:** It allows us to treat infrastructure as software. It provides a version-controlled, reproducible, and auditable history of every change to the platform.

## How do you secure the platform?
"I apply a Zero-Trust model. At the network level, Snowflake Network Policies restrict access to corporate VPNs and AWS VPCs. At the platform level, we enforce a strict Role-Based Access Control (RBAC) hierarchy. At the data level, we use Snowflake Object Tags to identify PII, and apply Dynamic Data Masking so only authorized roles can view sensitive data like emails. Lastly, we don't store passwords; CI/CD uses OIDC, and Airflow fetches credentials dynamically from AWS Secrets Manager."

## How do you optimize cost?
"FinOps is baked into the architecture. First, workload isolation prevents noisy-neighbor problems. Second, I configure Resource Monitors with hard suspend limits so warehouses physically cannot exceed their monthly budget. Third, I set statement timeouts to kill runaway queries. Finally, at the data level, I refactored large dbt models from full-refresh to incremental, and applied Snowflake Clustering Keys to massive fact tables, reducing partition scans and cutting query costs by over 90%."

## How do you recover from failures?
"I rely on Snowflake Time Travel. If an analyst accidentally drops a table, I can run `UNDROP` in 30 seconds. If a pipeline corrupts data, I can use Time Travel to query the data exactly as it was 10 minutes ago, create a Zero-Copy Clone of that pristine state, and swap it into production. For infrastructure failures, because everything is codified in Terraform, our RTO to completely rebuild the environment from scratch is under 60 minutes. We validate this with quarterly DR drills."

## What would you improve in Phase 2?
"I would introduce Apache Iceberg for our massive, infrequently queried raw logs to save on Snowflake storage costs. I would also leverage Snowflake Cortex for in-warehouse GenAI, allowing us to perform sentiment analysis on customer reviews without extracting the data. Finally, I'd migrate our batch ingest to Snowpipe Streaming to achieve sub-second latency for clickstream analytics."
