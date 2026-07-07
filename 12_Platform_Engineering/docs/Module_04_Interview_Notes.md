# Interview Notes: Secrets & Configuration Management

## Q: How do you secure credentials in your CI/CD pipelines?
**A:** "A massive anti-pattern is storing long-lived AWS Access Keys in GitHub Secrets. To eliminate this, I implemented OpenID Connect (OIDC). My GitHub Actions pipeline authenticates to AWS dynamically by exchanging an identity token for short-lived IAM credentials. The AWS IAM Trust Policy strictly verifies that only my specific GitHub repository on the 'main' branch can assume the deployment role. No static keys exist."

## Q: How do you manage secrets for Airflow and Snowflake?
**A:** "I enforce complete separation of code and configuration. No credentials exist in Airflow Python files or dbt profiles. I provisioned AWS Secrets Manager using Terraform and encrypted it with a custom AWS KMS Key. Airflow is configured with the `SecretsManagerBackend`, meaning it fetches credentials (like the Snowflake Key-Pair or dbt Cloud API Token) dynamically at runtime, holds them in memory just long enough to execute the task, and then purges them."

## Q: How do you handle Secret Rotation?
**A:** "For highly privileged service accounts, like the Airflow to Snowflake connection, I use RSA Key-Pair authentication rather than passwords. I wrote a Python script (`rotate_snowflake_keys.py`) that acts as a cron job. It generates a new OpenSSL key pair, pushes the new private key to AWS Secrets Manager, and immediately issues an `ALTER USER` command to Snowflake to update the public key, achieving zero-downtime rotation."
