# Interview Notes: Enterprise Streams

## "Why use Snowflake Streams instead of managing timestamp watermarks manually?"
**Answer:** Manually managing watermarks (e.g., `WHERE updated_at > last_run_timestamp`) is notoriously fragile. It suffers from the "late-arriving data" problem: if a record arrives late but has an older timestamp, it is missed by the watermark query forever. Snowflake Streams solve this by tracking exact micro-partitions and row offsets at the metadata level. Every single inserted row is guaranteed to enter the stream exactly once, regardless of its logical timestamp.

## "How did you optimize the CDC costs for the raw ingestion layer?"
**Answer:** Because our Bronze layer is populated via Snowpipe (which only issues INSERTs), I explicitly configured the streams as `APPEND_ONLY = TRUE`. Standard streams incur compute overhead to track the row-level differences for UPDATEs and DELETEs. By disabling this, we completely eliminated the metadata overhead on tables receiving millions of inserts per day.

## "What happens if a stream goes stale?"
**Answer:** Streams track the delta of the underlying table. If the underlying table's data retention period expires (typically 14 days), the stream offset becomes invalid ("stale") because the historical data it needs to compute the delta has been purged. If this happens, we must drop and recreate the stream. To recover the lost data, we fall back to a high-watermark replay strategy, forcing a bulk reload of the missed window before turning the new stream back on.

## "Why do you use `SYSTEM$STREAM_HAS_DATA()` to trigger tasks instead of just running `SELECT COUNT(*) FROM stream`?"
**Answer:** This is a common misconception! It is true that running `SELECT COUNT(*)` on a standard *Table* is a metadata-only operation that does not require a Virtual Warehouse. However, a **Stream** is not a physical table; it is a time-travel offset. 
To resolve `SELECT COUNT(*) FROM stream`, Snowflake must physically scan the underlying table's micro-partitions, compare them to the stream's offset, calculate the delta, and then aggregate the result. **This absolutely requires a running Virtual Warehouse and burns compute credits.**
If we ran a Task every 1 minute that executed `SELECT COUNT(*)`, we would keep the warehouse spinning 24/7. `SYSTEM$STREAM_HAS_DATA()`, on the other hand, is a specialized Cloud Services function that simply checks if the underlying table version has incremented past the stream's offset. It returns TRUE/FALSE instantly *without* spinning up the Virtual Warehouse, saving us massive amounts of compute credits.

## "In your `VW_CDC_ACTIVE_STREAMS` view, you call it a 'Volume Monitor', but `SYSTEM$STREAM_HAS_DATA` only returns TRUE or FALSE. How do you actually monitor exact row volume?"
**Answer:** That's a great catch. The `VW_CDC_ACTIVE_STREAMS` view acts as a lightweight "Activity Monitor" rather than an exact row-counter. Its primary purpose is for our alerting system (like Datadog or Airflow). If that view returns `TRUE` for a stream for more than 4 consecutive hours, it means the stream has volume, but the Task is failing to consume it (a blocked pipeline). It alerts us without burning warehouse credits.

**To get the exact row volume**, we don't query the stream directly. Instead, we rely on our **Audit Framework**.
Every time our CDC Tasks run successfully, the `MERGE` statement stored procedure captures the exact `Rows_Inserted` and `Rows_Updated` counts. It writes those exact volumes into our central audit table: `DB_PROD_METADATA.SC_META_PIPELINE.TB_CDC_EXECUTION_LOG`. 
This is the true Volume Monitor. It allows our Data Engineering dashboards to track exact throughput over time (e.g., 500,000 rows processed per day) accurately and cheaply!

## "So you have these views and audit tables... but how do they actually connect to a dashboard, and how do they stay updated in real-time?"
**Answer:** This is where the DataOps (Data Operations) layer comes in. The views and tables in Snowflake are just the storage mechanism. To make them actionable, we connect them to Enterprise Observability tools in two ways:

**1. How they stay updated:**
The Views (like `VW_CDC_ACTIVE_STREAMS`) evaluate dynamically. The moment a dashboard runs a query against it, Snowflake executes `SYSTEM$STREAM_HAS_DATA` in real-time. The Audit Tables (like `TB_CDC_EXECUTION_LOG`) are continuously appended to by the scheduled Snowflake CDC Tasks every 15 minutes.

**2. BI Dashboards (Visual Monitoring):**
We create a dedicated Service Account in Snowflake (e.g., `SVC_MONITORING_ROLE`). We plug those credentials into a BI tool (like **Tableau**, **PowerBI**, or even Snowflake's native **Snowsight** dashboards). The BI tool is configured to run a "Direct Query" against `TB_CDC_EXECUTION_LOG` every hour, plotting a beautiful time-series graph of "Rows Processed per Hour" for the engineering team to look at on a TV screen in the office.

**3. Automated Alerting (Datadog / PagerDuty):**
Dashboards are nice, but nobody stares at them 24/7. For true alerting, we use an observability tool like **Datadog**. Datadog's Snowflake integration runs a scheduled query against `VW_CDC_ACTIVE_STREAMS` every 10 minutes. 
The Datadog monitor rule is simple: *If `has_data` is TRUE for a stream, AND no successful run has been logged in `TB_CDC_EXECUTION_LOG` for the last 4 hours, trigger a critical alert.* Datadog then immediately fires a webhook to **PagerDuty**, which texts the on-call Data Engineer at 3:00 AM to fix the pipeline!

## "In your SCD1 MERGE script, you query `METADATA$ACTION` and `METADATA$ISUPDATE`. These columns don't exist on the base table. How does this work?"
**Answer:** This is the magic of Snowflake Streams! When you query a stream, Snowflake automatically appends three hidden, virtual metadata columns to the result set: `METADATA$ACTION` (INSERT or DELETE), `METADATA$ISUPDATE` (TRUE or FALSE), and `METADATA$ROW_ID`.

Because we configured the Currency stream as a **Standard Stream** (meaning we did *not* use `APPEND_ONLY = TRUE`), Snowflake's Cloud Services layer tracks every single DML operation performed on the base table. 
* If a row is updated in the base table, the stream emits two records: a DELETE (`ISUPDATE=TRUE`) for the old state, and an INSERT (`ISUPDATE=TRUE`) for the new state.
* If a row is hard-deleted in the base table, the stream emits one record: a DELETE (`ISUPDATE=FALSE`).

This allows our `MERGE` statement to easily capture hard-deletes from the source system and convert them into "soft deletes" (`is_deleted = TRUE`) in the Silver layer, all without ever modifying the schema of the underlying raw table!
