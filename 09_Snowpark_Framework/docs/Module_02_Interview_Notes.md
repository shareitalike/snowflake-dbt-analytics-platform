# Interview Notes: Configuration & Session Management

## Q: How do you manage Snowpark sessions?
**A:** "In a production setting, you never instantiate a `Session.builder.configs().create()` directly in the business logic. I build a `SnowflakeSessionFactory` that acts as a Context Manager (`with` block). This abstracts away the credential retrieval, injects exponential backoff using the `tenacity` library for resilience, runs a `.sql("SELECT 1")` health check, and most importantly, guarantees `session.close()` is called on exit to prevent resource leaks and zombie queries."

## Q: How do you avoid hardcoded credentials?
**A:** "By implementing a strictly layered Secrets Strategy. The codebase never holds static keys. In local development, we load `.env` variables using `python-dotenv`. In production (like MWAA or ECS), we leverage an IAM Task Role to query AWS Secrets Manager via `boto3`. The `SecretsManager` class dynamically builds the connection dictionary before passing it to the Session Factory."

## Q: How do you support multiple environments?
**A:** "We use Configuration as Code, specifically TOML files parsed by `pydantic`. We have `dev.toml`, `qa.toml`, and `prod.toml`. The `ENVIRONMENT` OS variable dictates which file is parsed. Pydantic guarantees that the configurations are type-safe (e.g., integers remain integers). This guarantees strict RBAC isolation because the `prod.toml` forces the session into the `DATA_ENGINEER_PROD` role."

## Q: How do you handle connection failures?
**A:** "Cloud networks are inherently transient, so I follow the 'Design for Failure' principle. I wrap the session instantiation logic with `tenacity`, configuring a `retry_if_exception_type` specifically for Snowflake network exceptions. If the connection fails, it retries up to 3 times using an exponential backoff algorithm (e.g., 2 seconds, 4 seconds, 8 seconds) before officially throwing a critical error. This prevents micro-outages from failing a multi-hour ELT batch."

## Enterprise Best Practices Demonstrated
1. **Context Managers (`__enter__` / `__exit__`):** Ensures deterministic resource cleanup.
2. **Pydantic Validation:** Fails fast on misconfiguration instead of failing halfway through a pipeline.
3. **Exponential Backoff:** Standard enterprise pattern for API resilience.
4. **Dependency Injection:** The Session Factory does not hardcode the config loader; it receives it, making unit testing via mocks completely trivial.
