# Phase 09 - Module 2: Configuration & Session Management

This module contains the enterprise configuration loader and resilient session management implementation for the Snowpark framework.

## Deliverables Checklist

- [x] **Design Summary:** Documented environment isolation and resilience strategies.
- [x] **Repository Structure:** Added `credentials`, `session`, and `tests` directories.
- [x] **Configuration Files:** `dev.toml`, `qa.toml`, `prod.toml` generated.
- [x] **Session Management:** `SnowparkSessionFactory` created with Tenacity retries and Context Manager integration.
- [x] **Configuration Loader:** Pydantic-based `ConfigLoader` created for type-safe parsing.
- [x] **Secrets Strategy:** `SecretsManager` implemented with Boto3 for AWS Secrets Manager.
- [x] **Error Handling:** Custom exception hierarchy defined in `exceptions.py`.
- [x] **Unit Tests:** `test_config.py` and `test_session.py` implemented using Pytest mocks.
- [x] **Operational Runbook:** Documented troubleshooting for common production issues.

## Usage Example

```python
from src.session.session_factory import SnowparkSessionFactory

def run_pipeline():
    # Context manager automatically loads config, connects, and cleans up on exit
    with SnowparkSessionFactory() as session:
        df = session.table("DB_PROD_CURATED.SC_SILVER_SALES.TB_ORDERS")
        df.show()
```
