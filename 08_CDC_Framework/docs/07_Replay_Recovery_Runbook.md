# Production Runbook: Replay & Recovery

## 1. Failed Stream Consumption (Stale Stream)
**Symptom:** Airflow or `VW_CDC_STREAM_HEALTH` alerts that a stream has gone STALE. Data is no longer flowing to the Silver layer.
**Action:** 
1. Identify the associated Pipeline_ID from `TB_WATERMARK`.
2. Execute `CALL SP_RECOVER_STALE_STREAM('STREAM_NAME', 'BASE_TABLE_NAME', 'PIPELINE_ID');`.
3. The stream is instantly recreated. The next 15-minute Task execution will automatically consume the backlog.

## 2. Bad Code Deployment (The "Time Travel" Recovery)
**Symptom:** A bug in the `MERGE` logic (e.g., a bad CASE statement) was deployed to production. It ran for 2 hours, corrupting the Silver table, before an analyst caught it.

**The Mechanical Flow (How `SP_ROLLBACK_WATERMARK` works):**
If you look at the `16_recovery_framework.sql` file, this procedure is incredibly simple but powerful. 
1. It executes an `UPDATE` on the `TB_WATERMARK` table, physically changing the `High_Watermark` timestamp backward in time to the exact moment before the bad code was deployed.
2. It writes an immutable audit record to `TB_RECOVERY_LOG` containing the ITSM Ticket number, ensuring compliance.

**Action (The Runbook):** 
1. Suspend the CDC DAG (`ALTER TASK TSK_CDC_MASTER_SCHEDULE SUSPEND`) so it stops processing new data.
2. Deploy the hotfix to correct the `MERGE` logic in the stored procedure.
3. Execute the rollback: `CALL SP_ROLLBACK_WATERMARK('PIPE_SHOPIFY_ORDERS', '2026-07-13 14:00:00', 'INC-9942');`.
4. Resume the DAG. 

**Why this is genius (Idempotency in Action):**
Because our entire CDC framework is bound by the Watermark, the moment you resume the DAG, the Task wakes up and queries `TB_WATERMARK`. It sees the old timestamp (from 2 hours ago). It doesn't know there was an error. It simply grabs the last 2 hours of raw JSON from the Bronze layer and passes it through the *fixed* `MERGE` logic. Because our `MERGE` statement uses `QUALIFY ROW_NUMBER() = 1`, it safely and automatically **overwrites** the corrupted records with the correct data. You completely repaired 2 hours of data corruption without writing a single `DELETE` or `UPDATE` statement!

## 3. Duplicate Replay Requests
**Symptom:** IT Operations accidentally triggers `SP_REPLAY_DATE_RANGE` twice for the same time window.
**Action:** No action required. The underlying MERGE framework relies on Business Keys and Checksums. Processing the same exact payload twice will result in 0 rows updated on the second pass.

## 4. Interrupted Task Chain (Partial Failure)
**Symptom:** `TSK_CDC_CUSTOMER` succeeds, but `TSK_CDC_ORDERS` fails due to a temporary warehouse outage.
**Action:** 
Do NOT replay the entire Customer domain. Identify the failed batch in `VW_FAILED_BATCH_REGISTRY` for the Orders pipeline, and execute `CALL SP_REPLAY_FAILED_BATCH('BATCH_ID');`. The DAG will automatically self-heal and resume.
