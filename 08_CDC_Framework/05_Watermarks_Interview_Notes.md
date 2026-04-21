# Interview Notes: Enterprise Watermarks

## "Why use Watermarks if Snowflake Streams automatically track offsets?"
**Answer:** Redundancy and auditing. Snowflake Streams are fantastic for low-latency CDC, but they act as a black box. If a stream goes stale (e.g., after 14 days) or is accidentally dropped via `CREATE OR REPLACE TABLE`, you lose the offset permanently. By managing our own explicit `TB_WATERMARK` state, we maintain absolute control over extraction lineage. If a stream is lost, we simply query the High Watermark, pass it to an ad-hoc `SELECT ... WHERE updated_at > High_Watermark` query, recreate the stream, and resume processing with zero data loss.

## "Why not just use MAX(updated_at) directly from the target table?"
**Answer:** Querying `MAX(updated_at)` directly from a multi-billion-row fact table before every micro-batch introduces massive, unnecessary warehouse compute costs. By tracking the `High_Watermark` in a tiny, centralized control table (`TB_WATERMARK`), retrieving the checkpoint costs less than 1 millisecond and leverages Cloud Services caching, meaning we don't even need to spin up the `WH_TRANSFORM` warehouse to figure out where we left off.

## "How do you restart a failed pipeline without duplicating data?"
**Answer:** The architecture enforces a strict "Commit Protocol". A pipeline execution is logged in `TB_BATCH_CONTROL` as `STARTED`. It reads the Low Watermark but does NOT advance the global `High_Watermark` until the very end, via `SP_UPDATE_CHECKPOINT`. If the warehouse times out, the global watermark stays put. The next execution will grab the exact same Low Watermark. When the new batch hits the `MERGE` command, the `MERGE`'s idempotent matching (via Business Keys and Checksums) guarantees that any partially inserted records are simply updated in place, completely eliminating duplicate rows.

### The "Low Watermark Gap" Problem (Late Arrivals)
This is the classic "Kafka Consumer Lag" scenario. **You cannot rely on the Source System's `updated_at` timestamp to be the Single Source of Truth.**

If the Upstream Source (Shopify/POS) has a system outage and sends a batch of records 3 days late, those records will have timestamps from 3 days ago. Your Low Watermark will be from 1 hour ago.

**The Result:** The `Low_Watermark` filter will exclude these late records because their `updated_at` is older than the watermark.

**The Solution:**
Since your architecture relies on **Dual-Loading (Source + Stream)**, you handle this by ensuring your MERGE logic captures *all* available changes.

1.  **Source Tables:** When you select from the source tables (e.g., `SELECT * FROM SOURCE_TABLE`), you are selecting the *raw snapshot*.
2.  **Streaming:** The stream captures the *change metadata*.
3.  **Dual-Load Logic:** By merging from both the source snapshot and the stream, you guarantee you capture the "Snapshot-in-Time" of the source, which includes those late records.
4.  **Replay Mechanism:** If the pipeline fails completely, you can manually replay by updating the `Low_Watermark` in `TB_WATERMARK` to a date *before* the known outage.

**Interview Answer:**
> "That is an excellent question. If the source system experiences an outage and sends a batch of records with old timestamps, the `updated_at` filter will indeed exclude them. However, my architecture solves this with a **Dual-Load Pattern**.
>
> While the Streams handle the real-time delta, my MERGE logic queries the **Source System Tables** directly (e.g., `TB_SHOPIFY_ORDERS_S`). Because the MERGE operates on a **Snapshot-in-Time** and uses `GROUP BY Business_Key` to dedup records within that batch, it successfully ingests late-arriving records even if their timestamps are older than the High Watermark.
>
> If the entire pipeline fails for an extended period, we can manually **Rollback the Watermark** to a date prior to the outage, effectively forcing the pipeline to re-process the historical window."

