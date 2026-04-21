# Module 7: Enterprise Replay & Recovery Architecture

## 1. Design Summary

### Replay Strategy
Data engineering in distributed environments demands resilience. When a bad code deployment, a schema drift event, or a catastrophic failure corrupts data in the Silver layer, we must be able to surgically rewind and "replay" data from the Bronze layer. Our strategy leverages Snowflake's `Time Travel` and idempotent `MERGE` statements to allow surgical replays of individual batches, specific pipelines, or specific time ranges without duplicating data.

### Recovery Strategy
Recovery is the process of restoring the state metadata after a failure. If a Task DAG crashes, the Checkpoint Framework (Module 5) automatically handles batch rollback. This module provides the manual escalation procedures for when automated recovery fails (e.g., Watermark corruption, Stale Streams).

### Restart & Batch Recovery Strategy
* **Batch Restart:** Re-executing a `FAILED` batch ID. The framework reads the existing Low Watermark, extracts the same slice of data, and passes it through the idempotent `MERGE` again.
* **Stream Offset Recovery:** If a stream goes `STALE`, we recreate the stream utilizing `AT (TIMESTAMP => ...)` to rewind the stream offset to match the `High_Watermark` recorded in `TB_WATERMARK`.

### Idempotent Replay
The entire CDC pipeline is structurally idempotent. A replay is literally just invoking the standard `MERGE` logic (Module 4) over a historical set of data. If the data is already correct in the Silver layer, the replay evaluates to `0 rows updated`. If the data was corrupted, the replay overwrites it with the correct values.

### Partial Failure Recovery
If a Task DAG succeeds on Customers but fails on Orders, we do not replay the entire DAG. The Replay framework targets specific `Pipeline_IDs`, allowing us to replay the Orders task independently.

### Disaster Recovery Considerations
If a regional outage destroys the active Snowflake account, the secondary (failover) account will have the replicated `TB_WATERMARK` state. Upon failover, the Task DAG resumes exactly where it left off, reading from the replicated Watermarks.

## 2. Quarantine Integration
In Phase 07 (Ingestion), we created a Dead Letter Queue (DLQ) for Snowpipe payload failures. This Replay framework integrates with the DLQ. If a payload is fixed (e.g., the JSON structure is repaired), it is flagged in the DLQ and the `SP_REPLAY_SINGLE_FILE` procedure extracts the corrected payload and pushes it into the Silver layer.

## 3. Audit Logging & Operational Monitoring
Every manual replay or recovery operation is heavily audited in `TB_RECOVERY_LOG`. 
* **Monitoring:** Security teams monitor this table to ensure replays are not used maliciously to alter historical financial records without a valid IT Service Management (ITSM) ticket.
