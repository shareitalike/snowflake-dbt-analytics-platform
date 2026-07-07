# Production Runbook: Late Arriving Data

## 1. Missing Dimensions (Ghost Record Proliferation)
**Symptom:** You notice thousands of records in `TB_CUSTOMER_DIM` where `source_system = 'INFERRED_GHOST'` and they have never been updated with real data.
**Cause:** The source system (e.g., Shopify) is generating Orders with invalid `Customer_IDs` that simply do not exist, or the Customer Snowpipe ingestion has silently failed upstream.
**Action:** 
1. Check the AWS Landing Zone and Snowpipe status for `TB_RAW_SHOPIFY_CUSTOMER`. 
2. If the data simply doesn't exist, this is a source system bug. The Ghost framework is operating correctly by preserving the Fact data, but the Data Stewards must be alerted to the corrupted source references.

## 2. Replay Conflicts (Historical Corrections)
**Symptom:** A Data Steward manually forces a historical `UPDATE` on a record, but the CDC pipeline immediately overwrites it.
**Cause:** The Data Steward updated a historical column but did not update the `source_updated_at` timestamp. Because the CDC stream holds a payload with a newer timestamp, the idempotent MERGE assumes the stream data is the most accurate.
**Action:** 
Any manual corrections applied directly to the Silver layer MUST set the `source_updated_at` to a timestamp far in the future (e.g., `CURRENT_TIMESTAMP()`) to ensure it wins the `tgt.updated_at < src.updated_at` validation within the MERGE statement.

## 3. Duplicate Reprocessing 
**Symptom:** Will a late arriving Order duplicate if the stream is re-run?
**Answer:** No. Facts are merged using their business keys. If the same late arriving order is processed twice, the second run evaluates to 0 rows updated because the checksum matches perfectly.

## 4. Time Zone Differences
**Symptom:** Records from Oracle ERP (EST) seem to constantly overwrite Shopify (UTC) records incorrectly.
**Prevention:** As defined in our core architecture, ALL timestamp columns are stored as `TIMESTAMP_LTZ`. Snowflake normalizes all inputs to UTC internally. If a source system sends a timezone-unaware string, it must be explicitly cast using `CONVERT_TIMEZONE` in the Stored Procedure before hitting the `MERGE`.
