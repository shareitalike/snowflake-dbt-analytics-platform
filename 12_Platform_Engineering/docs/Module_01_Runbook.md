# Operational Runbook: Terraform Enterprise

## Common Production Issues

### 1. State Lock Error
**Symptom:** Running `terraform apply` returns an `Error acquiring the state lock` pointing to DynamoDB.
**Root Cause:** Another CI/CD runner is currently executing an apply, or a previous execution crashed unexpectedly without releasing the lock.
**Resolution:**
If you verify that no other pipeline is running, manually release the lock using the command: `terraform force-unlock <LOCK_ID>`.

### 2. Configuration Drift
**Symptom:** `terraform plan` shows changes to AWS S3 bucket tags or Snowflake warehouse sizes, even though no code was changed in Git.
**Root Cause:** A DBA or Cloud Admin manually logged into the Snowflake/AWS console and changed a setting directly (ClickOps).
**Resolution:**
Terraform is designed to correct drift. Running `terraform apply` will automatically revert the manual changes back to the state defined in code. Notify the admin that manual changes are prohibited in a GitOps environment.

### 3. Secret Rotation Failure
**Symptom:** Terraform fails to authenticate to Snowflake.
**Root Cause:** The `SNOWFLAKE_PASSWORD` environment variable used by the CI/CD pipeline has expired.
**Resolution:**
Rotate the service account password in Snowflake, update the corresponding value in AWS Secrets Manager (or GitHub Secrets), and re-run the pipeline.
