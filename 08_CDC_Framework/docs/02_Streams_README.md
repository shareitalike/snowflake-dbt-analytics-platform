# Module 2: Enterprise Streams Framework

## Overview
This module physically implements the CDC Streams defined in the Phase 08 Architecture. Snowflake Streams provide exact-once processing semantics without requiring explicit manual offset management.

## Stream Strategy & Selection

### 1. Append-Only Streams (`APPEND_ONLY = TRUE`)
**Applied To:** Shopify, POS, Stripe, Salesforce (All domains ingested via Snowpipe).
**Why Selected:** Snowpipe relies on `COPY INTO`, which performs `INSERT` operations only. Since the raw payload is never explicitly updated or deleted in the Bronze layer, tracking UPDATE/DELETE metadata is a waste of Snowflake compute and storage. `APPEND_ONLY = TRUE` forces the stream to ignore any DML other than inserts, yielding a massive performance improvement on highly active Bronze tables.

### 2. Standard Streams
**Applied To:** Oracle ERP, Reference Data.
**Why Selected:** These sources are loaded via external tools (e.g., Fivetran, direct DML) that execute physical `UPDATE` and `DELETE` commands on the Bronze tables. To accurately compute the delta for the Silver MERGE, we must capture the full lifecycle of the row (`METADATA$ACTION = 'DELETE'` / `METADATA$ACTION = 'INSERT'`).

## Best Practices Enforced
* **Transaction Bounds:** Stream offsets only advance when consumed within a successful `COMMIT`. This guarantees zero data loss if the downstream Task fails.
* **Proactive Monitoring:** Created `VW_CDC_STREAM_HEALTH` to alert if streams approach their 14-day retention limit (becoming "stale").
* **Efficient Polling:** Orchestrators should query `SYSTEM$STREAM_HAS_DATA()` rather than `SELECT COUNT(*)` to check if a stream has data, as it queries metadata instantly without spinning up a warehouse.
