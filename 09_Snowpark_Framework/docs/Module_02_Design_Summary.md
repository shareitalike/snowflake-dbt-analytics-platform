# Enterprise Configuration & Session Management
## Module 02 - Design Summary

### Configuration Management Strategy
The framework adopts a strict **"Configuration as Code"** strategy using `TOML` files. 
- **Type Safety:** Configurations are loaded and validated using Python's `pydantic` library. If a configuration value (e.g., `max_retries`) is expected to be an integer but is passed as a string, Pydantic immediately throws a `ConfigValidationError` before the pipeline begins execution.
- **Hierarchical Overrides:** Configuration is resolved in the following order (highest precedence first):
  1. Environment Variables (e.g., `SNOWFLAKE_WAREHOUSE`)
  2. Environment-specific TOML file (e.g., `prod.toml`)
  3. Default fallback values defined in Pydantic models.

### Environment Isolation
Environments (DEV, QA, PROD) are isolated both logically (RBAC) and physically (TOML configurations). 
- The `ENVIRONMENT` system variable dictates which `config.toml` is loaded.
- By enforcing `DATABASE` and `ROLE` parameters at the TOML level, we prevent a developer from accidentally executing Snowpark code against `DB_PROD_CURATED` while using the DEV configuration.

### Session Lifecycle
Snowflake Sessions via the Snowpark API are expensive to instantiate and memory-intensive to maintain.
1. **Creation:** Sessions are created via the `SnowparkSessionFactory`, which abstracts the connection parameters.
2. **Resilience:** If network instantiation fails, the factory uses `tenacity` for exponential backoff (e.g., retry 3 times, waiting 2s, 4s, 8s).
3. **Health Checks:** Before yielding a pooled session, `session.sql("SELECT 1").collect()` is executed to ensure the socket hasn't timed out.
4. **Graceful Shutdown:** The factory operates as a Python Context Manager (`with SnowparkSessionFactory() as session:`). When the block exits, `session.close()` is guaranteed to execute, preventing orphaned sessions and zombie queries.

### Secrets Management
- **Local / CI Environment:** Secrets are injected via standard `.env` files or CI/CD pipeline variables.
- **Production:** The `SecretsManager` class integrates with **AWS Secrets Manager** via `boto3`. The pipeline executes with an IAM Task Role that grants `secretsmanager:GetSecretValue`. No usernames, passwords, or private keys exist in the repository or configuration files.
