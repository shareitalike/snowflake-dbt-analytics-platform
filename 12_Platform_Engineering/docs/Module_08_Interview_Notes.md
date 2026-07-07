# Interview Notes: Disaster Recovery & Business Continuity

## Q: How does Snowflake Time Travel work?
**A:** "Time Travel allows you to query or restore data to any point within the configured retention window. I set Bronze to 90 days and Gold to 1 day. If a bad MERGE corrupts `DIM_CUSTOMER` at 10:15 AM, I can create a Zero-Copy Clone of the table `AT (TIMESTAMP => '10:00 AM')` in seconds, then atomically swap it into production using `ALTER TABLE RENAME`. The corrupted version is preserved for investigation."

## Q: When do you use Zero-Copy Clones?
**A:** "I use them for three things. First, **Disaster Recovery**: cloning a table to its pre-corruption state using Time Travel. Second, **Environment Provisioning**: cloning the entire production database to create a QA environment instantaneously with zero storage cost. Third, **Safe Experimentation**: a Data Scientist can clone a table, run destructive analytics, and drop the clone without impacting production. The clone is free until they modify data (copy-on-write)."

## Q: How do you define RTO and RPO for a data platform?
**A:** "RPO is how much data you can afford to lose. RPO = 0 means zero data loss. In our platform, Snowflake Time Travel gives us RPO = 0 for up to 90 days. RTO is how fast you can recover. Our Snowflake table RTO is 30 seconds (UNDROP). Our full infrastructure RTO is 60 minutes (Terraform destroy + apply). We validate these targets quarterly with structured DR drills."

## Q: How do you test disaster recovery?
**A:** "Untested DR plans are fiction. I run three quarterly drills: (1) **Table Recovery:** Drop a test table and time the UNDROP. Must complete in < 5 minutes. (2) **Pipeline Recovery:** Deliberately fail the master Airflow DAG, clear task instances, re-trigger, and validate dbt output. Must complete in < 30 minutes. (3) **Full Environment Recovery:** Terraform destroy the QA environment and rebuild it from scratch. Must complete in < 60 minutes."
