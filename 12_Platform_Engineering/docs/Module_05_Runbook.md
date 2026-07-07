# Operational Runbook: Security & Governance

## Common Production Issues

### 1. Row Access Policy Conflicts
**Symptom:** A Data Scientist queries `FCT_SALES` and receives 0 rows, even though data exists.
**Root Cause:** The user is assigned the `DATA_SCIENTIST_ROLE`, but the Row Access Policy only permits `GLOBAL_ADMIN_ROLE` or specific Regional Managers to view rows. 
**Resolution:**
Update the Row Access Policy in Terraform (`row_access/main.tf`) to explicitly handle the `DATA_SCIENTIST_ROLE` in the `CASE` statement, then run `terraform apply`.

### 2. Network Policy Misconfiguration
**Symptom:** Airflow DAGs fail immediately with a Snowflake connection timeout or authorization error.
**Root Cause:** The IP address of the AWS NAT Gateway changed (or a new one was added), and it was not added to the `ENTERPRISE_MASTER_POLICY` allowed IP list.
**Resolution:**
Update the `network_policies.sql` file (or the Terraform equivalent) to include the new NAT Gateway IP.

### 3. PII Exposure Audit
**Symptom:** The Compliance Officer wants to know exactly who queried email addresses last week.
**Root Cause:** Routine SOX/GDPR compliance check.
**Resolution:**
Execute the `access_history_queries.sql` script as `ACCOUNTADMIN`. This queries the Snowflake `ACCESS_HISTORY` view, returning the exact `query_id`, `user_name`, and timestamp of any user who queried a column tagged with `PII_DATA`.
