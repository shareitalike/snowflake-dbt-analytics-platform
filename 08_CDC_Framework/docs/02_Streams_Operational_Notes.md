# Operational Notes & Common Production Problems

## 1. Stale Streams
**Problem:** A stream is queried and throws an error that it is STALE.
**Cause:** The stream was not consumed within the `DATA_RETENTION_TIME_IN_DAYS` of the base table (e.g., the Task was paused for 15 days). Alternatively, someone executed `CREATE OR REPLACE TABLE` on the base table.
**Resolution:** 
1. Run `03_rollback_scripts.sql` to Drop/Recreate the stream.
2. Execute a High-Watermark Replay to patch the missing data window.

## 2. Offset Management & Ghost Consumptions
**Problem:** Data is inserted into the base table, but the stream is empty, yet the downstream Silver table didn't receive the data.
**Cause:** A developer or analyst ran a `SELECT * FROM STREAM` outside of an explicit transaction (`BEGIN; ... COMMIT;`), or ran a DML operation consuming the stream manually. This consumes the offset permanently!
**Resolution:** 
* Preventative: `DATA_ENGINEER` is the only role with USAGE on the stream.
* Corrective: Replay the lost records via manual `MERGE`.

## 3. Schema Evolution (DDL Changes)
**Problem:** You add a new column to the Bronze table. Does the stream break?
**Answer:** No. Snowflake Streams automatically inherit schema evolution. The new column will immediately appear in the stream data.

## 4. Performance Considerations
* **Micro-partition Pruning:** Do NOT apply standard `WHERE` clauses to a stream query (e.g., `SELECT * FROM STREAM WHERE date = '2023-01-01'`). Streams are heavily optimized to return the raw delta. If filtering is required, filter inside the downstream `MERGE` statement, not the stream extraction.
* **Credit Consumption:** Using `SYSTEM$STREAM_HAS_DATA` costs 0 credits. It relies on the Cloud Services layer. Airflow sensors should poll this function heavily without fear of spinning up the `WH_TRANSFORM` warehouse.
