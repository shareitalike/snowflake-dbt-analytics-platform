# Phase 09 - Module 10: Enterprise End-to-End Snowpark Pipeline

This module represents the final integration of the Enterprise Snowpark Framework. It weaves together the capabilities of Modules 1 through 9 into a unified, resilient `PipelineOrchestrator`.

## Deliverables Checklist

- [x] **Architecture Overview:** Documented the Mermaid execution flow (Landing -> Session -> Validate -> Lookups -> Silver -> dbt).
- [x] **Repository Structure:** Created `orchestration/` module.
- [x] **Pipeline Orchestrator:** Implemented `PipelineOrchestrator`, wrapping business logic inside Audit Context Managers and metric collectors.
- [x] **Error Handling:** Designed the orchestrator to trap catastrophic failures, flush metadata, and return structured states rather than crashing blindly.
- [x] **Unit Tests:** `test_end_to_end.py` validating orchestrator routing and exception trapping.
- [x] **Operational Runbook:** Documented troubleshooting for "Silent Failures" and "Connection Pool Exhaustion".

## Usage Example (End-to-End Execution)

```python
from src.orchestration.pipeline_orchestrator import PipelineOrchestrator
from src.session.factory import SessionFactory

# Initialize external session
session = SessionFactory.create_session()

# Initialize Orchestrator
orchestrator = PipelineOrchestrator(session, logger)

# Define custom business logic (utilizing modules 4, 5, 6, 7)
def shopify_ingestion_logic(session, audit_tracker, metrics_collector):
    # 1. Read CDC Stream
    # 2. JSON Flatten (Module 6)
    # 3. Validate Schema (Module 4)
    # 4. Temporal Join Lookups (Module 7)
    
    return {
        "rows_read": 5000,
        "rows_written": 4900,
        "rows_rejected": 100
    }

# Execute
is_success = orchestrator.execute(
    pipeline_id="PIPE_SHOPIFY_BRONZE_TO_SILVER",
    warehouse="WH_INGEST_XSMALL",
    business_logic_closure=shopify_ingestion_logic
)

if not is_success:
    raise Exception("Pipeline failed. Halting dbt DAG.")
```
