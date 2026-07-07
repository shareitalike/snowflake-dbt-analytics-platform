# Production Runbook: Replay & Recovery

## 1. Failed Stream Consumption (Stale Stream)
**Symptom:** Airflow or `VW_CDC_STREAM_HEALTH` alerts that a stream has gone STALE. Data is no longer flowing to the Silver layer.
**Action:** 
1. Identify the associated Pipeline_ID from `TB_WATERMARK`.
2. Execute `CALL SP_RECOVER_STALE_STREAM('STREAM_NAME', 'BASE_TABLE_NAME', 'PIPELINE_ID');`.
3. The stream is instantly recreated. The next 15-minute Task execution will automatically consume the backlog.

## 2. Incorrect Watermark / Bad Code Deployment
**Symptom:** A bug in the `MERGE` logic was deployed to production. It ran for 2 hours, corrupting Silver data, before it was caught.
**Action:** 
1. Suspend the CDC DAG (`ALTER TASK TSK_CDC_MASTER_SCHEDULE SUSPEND`).
2. Deploy the hotfix to correct the `MERGE` logic.
3. Execute `CALL SP_ROLLBACK_WATERMARK('PIPE_ID', 'TIMESTAMP_BEFORE_DEPLOYMENT', 'INC12345');`.
4. Resume the DAG. The framework will automatically read the rolled-back watermark and re-extract the corrupted time window. The idempotent `MERGE` will overwrite the bad records with the newly corrected logic.

## 3. Duplicate Replay Requests
**Symptom:** IT Operations accidentally triggers `SP_REPLAY_DATE_RANGE` twice for the same time window.
**Action:** No action required. The underlying MERGE framework relies on Business Keys and Checksums. Processing the same exact payload twice will result in 0 rows updated on the second pass.

## 4. Interrupted Task Chain (Partial Failure)
**Symptom:** `TSK_CDC_CUSTOMER` succeeds, but `TSK_CDC_ORDERS` fails due to a temporary warehouse outage.
**Action:** 
Do NOT replay the entire Customer domain. Identify the failed batch in `VW_FAILED_BATCH_REGISTRY` for the Orders pipeline, and execute `CALL SP_REPLAY_FAILED_BATCH('BATCH_ID');`. The DAG will automatically self-heal and resume.
