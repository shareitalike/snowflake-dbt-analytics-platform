# Interview Notes: Pipeline Operations (Stopping & Pausing)

## 1. "How do you pause or stop a Snowflake Stream?"
**Answer (TRICK QUESTION!):** You **cannot** technically "pause" or "stop" a Snowflake Stream. A Stream is not an active compute process; it is purely a metadata pointer (an offset). It passively tracks changes on the base table.

**The Production Solution:** 
If you want to "stop" data from flowing, you **suspend the Task** that consumes the Stream. The Stream will simply continue to passively build up a backlog of delta records. 
*Warning:* You can safely leave the task paused for up to 14 days (the standard time travel retention period). If you wait longer than 14 days, the Stream will become *stale* and must be recreated.

---

## 2. "How do you pause or stop a Snowflake Task?"
**Answer:** You use the `ALTER TASK` command to suspend it. 

**Production Scenario:** 
Our dbt tests in the Silver layer are failing because of a schema drift issue. We need to stop the Bronze-to-Silver CDC pipeline immediately so we don't corrupt the Silver tables while we write a hotfix.

**SQL Code:**
```sql
-- Stop the task (Pauses execution immediately)
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_ORDERS SUSPEND;

-- ... Engineer fixes the issue ...

-- Resume the task 
ALTER TASK DB_PROD_CURATED.SC_UTILITIES.TSK_CDC_ORDERS RESUME;
```
*Note:* When you resume the task, it will automatically process the entire backlog of data sitting in the Stream all at once during its next scheduled run.

---

## 3. "How do you pause or stop a Snowpipe?"
**Answer:** You use the `ALTER PIPE` command and set the `PIPE_EXECUTION_PAUSED` parameter to `TRUE`.

**Production Scenario:** 
The upstream AWS S3 bucket (or Azure Blob) was accidentally contaminated with malformed JSON files from a broken Shopify API. We need to stop Snowpipe from automatically auto-ingesting these bad files into the Bronze layer.

**SQL Code:**
```sql
-- Stop Snowpipe auto-ingestion
ALTER PIPE DB_PROD_RAW.SC_BRONZE_SHOPIFY.PIPE_SHOPIFY_ORDERS 
SET PIPE_EXECUTION_PAUSED = TRUE;

-- Check the status of the pipe to confirm it is paused
SELECT SYSTEM$PIPE_STATUS('DB_PROD_RAW.SC_BRONZE_SHOPIFY.PIPE_SHOPIFY_ORDERS');

-- ... Engineer deletes the bad files from S3 ...

-- Resume the pipe
ALTER PIPE DB_PROD_RAW.SC_BRONZE_SHOPIFY.PIPE_SHOPIFY_ORDERS 
SET PIPE_EXECUTION_PAUSED = FALSE;
```

---

## 4. "How do you defer or pause a Dynamic Table?"
**Answer:** Similar to tasks, you `SUSPEND` the Dynamic Table so the automated refresh engine stops evaluating the DAG.

**Production Scenario:** 
You are performing a massive historical backfill on the raw tables. You don't want the Dynamic Tables (which have a 5-minute lag) to constantly try and refresh while you are inserting millions of rows over the next 2 hours.

**SQL Code:**
```sql
-- Pause the Dynamic Table refresh
ALTER DYNAMIC TABLE DB_PROD_CURATED.SC_SILVER_SALES.DT_SALES_FACT SUSPEND;

-- Resume the Dynamic Table refresh once the backfill is done
ALTER DYNAMIC TABLE DB_PROD_CURATED.SC_SILVER_SALES.DT_SALES_FACT RESUME;
```

---

### Interview Summary: 
* **Tasks & Dynamic Tables:** `ALTER ... SUSPEND / RESUME`
* **Snowpipes:** `ALTER PIPE SET PIPE_EXECUTION_PAUSED = TRUE / FALSE`
* **Streams:** Cannot be paused. Pause the consumer (Task) instead!
