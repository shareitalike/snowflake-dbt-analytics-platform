# Interview Notes: Enterprise Data Observability

## "How do you measure Data Freshness SLAs across a complex pipeline?"
**Answer:** Instead of relying on proxy metrics like "When did the Airflow DAG finish?", I built a framework that measures the exact physical latency of the data. I joined the `High_Watermark` from our control table (which explicitly tracks the timestamp of the last successful source payload merged) against `CURRENT_TIMESTAMP()`. If the gap exceeds 60 minutes, our internal alert procedure fires. This guarantees our business stakeholders are seeing the true freshness of the data, not just the technical execution status of a task.

## "How do you monitor warehouse costs and prevent runaway compute?"
**Answer:** I created the `VW_WAREHOUSE_CREDIT_USAGE` view which sits directly on top of `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`. By explicitly filtering on `WH_TRANSFORM`, we isolate the exact cost of the CDC process. Furthermore, we actively monitor the `CLOUD_SERVICES_CREDITS`. If these spike, it tells us that our Task scheduling is too aggressive (e.g., 1-minute intervals) or we are executing too many metadata operations without actual data movement.

## "How do you avoid Alert Fatigue?"
**Answer:** An alert that fires every 5 minutes for the same issue will quickly be ignored by engineers. In my `SP_EVALUATE_SLA_BREACHES` procedure, I implemented a strict deduplication check. The procedure only inserts a new alert if there is no `Is_Resolved = FALSE` alert currently active for that specific `Pipeline_ID`. This ensures the on-call engineer receives exactly one notification per incident.

## "What happens if your transformation logic (Silver/Gold) fails, but the data landed in Bronze?"
**Answer:** That is precisely why the `TB_BATCH_CONTROL` table is the system of record. If the Bronze task succeeds, the `High_Watermark` is advanced, and the metadata is committed. If the subsequent Silver task fails, we simply call our `SP_REPLAY_FAILED_BATCH` procedure. Since the procedure reads directly from the Immutable Bronze base table using the recorded timestamps, it reruns the transformation logic without affecting the already-processed stream offset, ensuring Bronze remains the persistent source of truth.

## 6. Advanced Question: Idempotency vs. Determinism
**Interviewer:** "Your `MERGE` logic uses `source_updated_at` to prevent duplicates. Is your pipeline deterministic?"
**Answer:** That is a key architectural distinction. The pipeline is **Idempotent** but not strictly **Deterministic**. 
*   **Idempotent:** Yes. Running the same batch twice produces the same result because we use `ROW_NUMBER() OVER (PARTITION BY BusinessKey ORDER BY SourceTimestamp)` and compare timestamps before updating.
*   **Deterministic:** No. If the **exact same** source record arrives twice within the same microsecond (rare but possible), the `ROW_NUMBER()` might assign `1` to the second record, and it would overwrite the first. However, for operational disaster recovery, we accept this trade-off because the data consistency is maintained (the record is still the same value), even if the specific internal row version changes. Real determinism would require a composite business key that is guaranteed unique to the atom of change.

