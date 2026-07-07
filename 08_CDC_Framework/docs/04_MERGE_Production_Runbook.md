# Production Runbook: MERGE Procedures

## 1. Duplicate Business Keys in Target
**Symptom:** `VW_DQ_DUPLICATE_ACTIVE_CUSTOMERS` returns results.
**Cause:** The source system (e.g. Shopify) allowed a duplicate ID, or a bug in the MERGE bypassed the idempotency checks.
**Action:** 
1. Suspend the CDC DAG (`TSK_CDC_MASTER_SCHEDULE`).
2. Run a manual deduplication script to force `is_current = FALSE` on the older version.
3. Resume the DAG.

## 2. Invalid Effective Dates
**Symptom:** `VW_DQ_OVERLAPPING_VALIDITY_WINDOWS` returns results.
**Cause:** The source system generated payloads where `updated_at` was identical down to the millisecond, or the stream processed them in the wrong order without proper ordering logic.
**Action:** 
Modify the `QUALIFY ROW_NUMBER()` logic inside the stored procedure to include a tie-breaker (e.g., `ORDER BY source_updated_at DESC, metadata$file_row_number DESC`).

## 3. Long Running MERGE Operations
**Symptom:** `SP_MERGE_ORDERS_TRANSACTIONAL` times out after 15 minutes.
**Cause:** The target table (`TB_ORDERS`) has grown to billions of rows, and the `MERGE ON tgt.order_id = src.order_id` is scanning too many micro-partitions.
**Action:** 
1. Check the `Query Profile` for massive "Table Scan" percentages.
2. Apply a Cluster Key to the target table: `ALTER TABLE TB_ORDERS CLUSTER BY (order_id)`.
3. Allow Automatic Clustering to optimize the partitions.

## 4. Concurrent MERGE Operations
**Symptom:** Transaction Rollback due to lock contention.
**Cause:** Two tasks attempted to MERGE into `TB_CUSTOMER_DIM` simultaneously.
**Action:** 
Ensure the Task DAG enforces dependencies correctly. No two tasks should ever write to the exact same Silver table concurrently.
