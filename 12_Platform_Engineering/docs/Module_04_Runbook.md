# Operational Runbook: Secrets Management

## Common Production Issues

### 1. OIDC Token Expiry (GitHub Actions)
**Symptom:** The GitHub Actions CI/CD pipeline fails at the `Configure AWS Credentials` step with an `AccessDenied` exception.
**Root Cause:** The IAM Trust Policy in AWS does not correctly match the repository name or branch name trying to assume the role.
**Resolution:**
Check the `aws_iam_role` trust policy in Terraform (`iam_oidc/main.tf`). Ensure that `token.actions.githubusercontent.com:sub` matches the exact string `repo:YourOrg/YourRepo:ref:refs/heads/main`.

### 2. Secret Rotation Failure (Snowflake)
**Symptom:** Airflow DAGs start failing with `Snowflake Authentication Error`.
**Root Cause:** The Snowflake RSA Key Pair for `AIRFLOW_SVC` expired or was corrupted during a rotation event.
**Resolution:**
Execute the `scripts/security/rotate_snowflake_keys.py` script. This script automatically generates a new 2048-bit RSA key pair, pushes the private key directly into AWS Secrets Manager, and executes an `ALTER USER` command in Snowflake to inject the new public key.

### 3. Missing Airflow Connection
**Symptom:** Airflow log says `Connection 'slack_api_default' not found`.
**Root Cause:** The `airflow_connections.yaml` file was modified but the backend wasn't updated.
**Resolution:**
Ensure that the secret ARN in AWS Secrets Manager matches the naming convention Airflow expects (`airflow/connections/slack_api_default`).
