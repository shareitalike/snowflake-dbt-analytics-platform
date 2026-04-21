# Interview Notes: Enterprise Replay & Recovery

## "How do you replay failed loads without duplicating data?"
**Answer:** The secret to safe replays is structural idempotency. Our Replay framework doesn't blindly insert data; it simply wraps our standard `MERGE` procedures in a historical `WHERE source_updated_at BETWEEN ...` clause against the Bronze base table. Because the `MERGE` strictly evaluates the incoming `MD5` Checksum and `updated_at` timestamps against the target, it guarantees that any data already successfully loaded is ignored, while missing or corrected data is successfully upserted.

## "How do you recover if a Snowflake Stream is accidentally dropped or goes stale?"
**Answer:** This is exactly why we built the independent Watermark Framework (Module 5). If a stream is lost, we don't panic. We simply query `TB_WATERMARK` to find the exact millisecond the pipeline last successfully committed. We then use Snowflake's Time Travel feature in a dynamic DDL execution: `CREATE STREAM ... AT (TIMESTAMP => 'High_Watermark')`. This rewinds the stream's offset, seamlessly bridging the gap between the target layer and the raw ingestion without missing a single row.

## "How do you handle partial failures in a heavily dependent DAG?"
**Answer:** By maintaining strict isolation at the Batch level. If the Order task fails but the Customer task succeeds, we don't roll back the entire platform. We locate the specific `Batch_ID` for the Order pipeline in `TB_BATCH_CONTROL`. The `SP_REPLAY_FAILED_BATCH` procedure surgically re-executes that single extraction slice. The dependency graph ensures the failed task won't block unrelated parallel pipelines, isolating the blast radius.

## 5. Real-World Scenario: The Holiday Code Freeze (Example of Stale Stream Recovery)
**The Scenario:** Your company enters a "Code Freeze" over the December holidays. A major downstream system is undergoing maintenance, so the Data Engineering team is ordered to pause the Snowflake CDC tasks that consume the `STR_SHOPIFY_ORDERS` stream.

**The Crisis:** The team intended to pause the pipeline for 10 days, but due to delays, the maintenance takes 16 days. 
When the engineer finally resumes the Snowflake Tasks on January 5th, the task immediately crashes with a fatal error: `Stream 'STR_SHOPIFY_ORDERS' has become stale.`

**The Junior Engineer's Mistake:** A junior engineer panics. They know they need a valid stream to run the pipeline, so they run:
`CREATE OR REPLACE STREAM STR_SHOPIFY_ORDERS ON TABLE SC_BRONZE_SHOPIFY.TB_ORDERS;`
The stream is now "fixed" and the pipeline runs successfully. **However, they just caused a massive data loss incident.** By recreating the stream normally, its "bookmark" was set to January 5th. All the Shopify orders that arrived between December 20th and January 5th were completely skipped by the stream. The business just lost 16 days of revenue reporting!

**The Senior Engineer's Heroics (Using your framework):** Instead of panicking, the Senior Engineer looks at the `TB_WATERMARK` table and sees that the `High_Watermark` for this pipeline is `2025-12-20 14:00:00`.
They simply run your procedure:
`CALL SP_RECOVER_STALE_STREAM('STR_SHOPIFY_ORDERS', 'TB_ORDERS', 'PIPE_SHOPIFY_ORDERS');`

**What happens next:**
1. The procedure drops the stale stream.
2. It executes `CREATE STREAM ... AT (TIMESTAMP => '2025-12-20 14:00:00')`.
3. The stream is perfectly resurrected. It points to the exact millisecond the pipeline was paused before the holidays. 
4. The engineer turns the Snowflake Tasks back on, and the pipeline seamlessly processes all 16 days of backlogged holiday data with absolutely zero data loss and zero duplicates!

---


