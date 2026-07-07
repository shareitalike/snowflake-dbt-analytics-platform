# Production Runbook: Watermarks & Checkpoints

## 1. Watermark Corruption
**Symptom:** A bug allowed an invalid date (e.g., year 9999) to be recorded in `TB_WATERMARK`, causing subsequent batches to extract 0 rows.
**Action:** 
Execute a manual update to roll back the watermark to a known good state:
`UPDATE DB_PROD_METADATA.SC_META_CONTROL.TB_WATERMARK SET High_Watermark = '2025-01-01 00:00:00' WHERE Pipeline_ID = 'PIPE_ORDERS';`
The next batch will automatically resume extraction from that timestamp.

## 2. Checkpoint Loss (Crash)
**Symptom:** A batch is stuck in `STARTED` status for 24 hours in `TB_BATCH_CONTROL`.
**Cause:** The warehouse crashed or the connection dropped before `SP_ROLLBACK_CHECKPOINT` could be fired.
**Action:** 
This is not fatal. Because `SP_UPDATE_CHECKPOINT` was never called, the Global Watermark was never advanced. The next scheduled DAG run will automatically pick up the correct Low Watermark. You can manually run `UPDATE TB_BATCH_CONTROL SET Status = 'FAILED' WHERE Status = 'STARTED' AND Execution_Start_Time < DATEADD(hour, -1, CURRENT_TIMESTAMP());` to clean up the metadata table.

## 3. Duplicate Processing
**Symptom:** A batch fails halfway through a `MERGE` operation, but is then restarted. Did we duplicate data?
**Answer:** No. 
1. The Checkpoint mechanism ensures we extract the exact same data again.
2. The `QUALIFY ROW_NUMBER` logic inside the MERGE (Module 4) ensures the data stream is deduplicated.
3. The MERGE `tgt.checksum != src.checksum` check ensures that any rows successfully inserted during the first failed attempt are not duplicated or needlessly updated on the second attempt.

## 4. Clock Drift & Timezone Issues
**Prevention:** All timestamp columns across the entire framework (from Bronze `ingestion_timestamp` to the Watermarks themselves) are strictly typed as `TIMESTAMP_LTZ` (Local Time Zone). Snowflake aligns `TIMESTAMP_LTZ` to UTC implicitly, completely preventing Daylight Savings Time or regional server timezone drift issues.
