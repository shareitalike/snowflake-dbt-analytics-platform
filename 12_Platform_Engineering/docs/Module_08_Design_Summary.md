# Enterprise Disaster Recovery & Business Continuity
## Module 08 - Design Summary

### Disaster Recovery Strategy
Our DR strategy is built on the principle that **the best disaster recovery is one where you don't lose data and don't need to rebuild infrastructure manually.**

Every component in our stack has a different recovery profile:
- **Snowflake:** Near-zero RPO via Time Travel (90 days on Bronze) and Fail-safe (7 days). Cross-Region Replication provides geographic resilience.
- **Airflow:** Stateless Control Plane. DAGs live in Git and are synced to S3 via CI/CD. Recovery = re-deploy from Git.
- **dbt Cloud:** The project IS the Git repository. Zero data loss. Recovery = re-trigger the dbt Cloud job.
- **Terraform:** State is stored in a versioned S3 bucket with DynamoDB locking. Recovery = `terraform init` from the versioned state.

### RTO / RPO Targets
- **RPO (Recovery Point Objective): 0 minutes** for all data components. Snowflake Time Travel ensures we can recover to any point within the retention window. Git ensures code is never lost.
- **RTO (Recovery Time Objective): 15 minutes** for the Control Plane (Airflow). 30 seconds for individual Snowflake tables (UNDROP). 60 minutes for a full environment rebuild via Terraform.

### Zero-Copy Cloning
One of the most powerful features in our DR toolkit is Snowflake's Zero-Copy Clone. Instead of running expensive CTAS operations to create QA environments, we clone the entire production database in seconds. The clone shares the underlying micro-partitions (zero additional storage cost) until data is modified (copy-on-write). This also serves as our primary mechanism for point-in-time recovery of corrupted data.
