# Phase 09 - Module 3: Enterprise Logging & Exception Framework

This module implements the core observability and error handling capabilities for the Snowpark framework.

## Deliverables Checklist

- [x] **Design Summary:** Documented structured JSON logging and exception categorization strategies.
- [x] **Repository Structure:** Added `logging` and `exceptions` directories.
- [x] **Exception Framework:** Created custom hierarchy in `hierarchy.py` separating `RetryableException` from `NonRetryableException`.
- [x] **Retry Framework:** Implemented exponential backoff with jitter using `tenacity` in `retry.py`.
- [x] **Logging Framework:** Created `JSONFormatter` for external observability (Datadog/Splunk).
- [x] **Specialized Loggers:** Implemented `EnterpriseLogger` and `AuditLogger`.
- [x] **Audit & Performance:** Implemented `AuditContext` and `PerformanceMetrics` Pydantic models.
- [x] **Unit Tests:** `test_logging.py` and `test_retry.py` validating fail-fast vs exponential backoff.
- [x] **Operational Runbook:** Documented troubleshooting for retry storms and duplicate logs.

## Usage Example (Retry & Exception)

```python
from src.exceptions import SnowflakeConnectionException, DataQualityException, with_retry

@with_retry
def fetch_data():
    # If this raises SnowflakeConnectionException, it will retry 3 times with exponential backoff.
    # If this raises DataQualityException, it fails immediately.
    pass
```
