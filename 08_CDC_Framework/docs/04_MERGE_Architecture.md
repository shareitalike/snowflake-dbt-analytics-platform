# Module 4: Enterprise MERGE Strategy

## MERGE Design Strategy

### Why MERGE?
The `MERGE` statement in Snowflake is the most efficient mechanism for applying Change Data Capture (CDC) streams to target tables. It allows us to process Inserts, Updates, and Soft Deletes in a single, atomic transaction. Using `MERGE` avoids the latency and complexity of maintaining separate staging tables and executing multi-step DML transactions, drastically reducing `WH_TRANSFORM` compute time.

### Idempotent Processing
Every MERGE procedure in this framework is strictly idempotent. If a task fails or is manually triggered multiple times, the target state remains identical. We achieve this by:
1. Identifying incoming duplicates within the stream payload using `QUALIFY ROW_NUMBER() OVER (PARTITION BY business_key ORDER BY updated_at DESC) = 1`.
2. Matching exactly on the Business Key.
3. Only updating if the `incoming_checksum != existing_checksum` or `incoming_updated_at > existing_updated_at`.

### Full Load vs Incremental
* **Full Load:** Executed via `COPY INTO` or direct `INSERT OVERWRITE` during disaster recovery.
* **Incremental:** Handled exclusively via the MERGE procedures, processing only the `APPEND_ONLY` stream delta.

### Key Strategy
* **Business Keys:** The natural primary key from the source system (e.g., `Shopify_Customer_ID`). Used exclusively in the `ON` clause of the MERGE to match records.
* **Surrogate Keys:** Generated dynamically during the MERGE using `MD5(Business_Key)`. Crucial for Type 2 SCDs to uniquely identify a specific *version* of a record.

### SCD Type 2 Attributes
For Customer, Product, Store, and Employee dimensions, we track history:
* **Current Flag (`IS_CURRENT`):** Boolean indicating the active version.
* **Effective Date (`VALID_FROM`):** The timestamp the change occurred.
* **Expiry Date (`VALID_TO`):** The timestamp the record was superseded (Default: `9999-12-31`).

### Delete Handling
* **Soft Deletes (Preferred):** If a source sends a deletion payload, the MERGE updates `IS_DELETED = TRUE` and closes the `VALID_TO` record. We never physically delete dimension data.
* **Logical Deletes:** Deletes inferred by a missing record in a full-table sync (handled externally, not in continuous CDC).
* **Hard Deletes (Compliance Only):** Executed via dedicated GDPR/CCPA purge tasks, entirely separate from the CDC micro-batch.

## Late Arriving Records Strategy
Because we operate in a distributed microservice environment (Shopify, POS, Oracle), payloads frequently arrive out of order.
1. The MERGE statement evaluates `incoming.updated_at > existing.updated_at`. 
2. If an older record arrives *after* a newer record has already been merged, the `MERGE` simply ignores the older record. The most recent state is always preserved.

## Audit Columns Framework
Every target table in the Silver layer includes the following audit footprint, generated during the MERGE:
* `CREATED_AT`: Timestamp the record first entered the platform.
* `UPDATED_AT`: Timestamp of the last DML operation.
* `SOURCE_SYSTEM`: The origination domain (e.g., 'SHOPIFY_API').
* `BATCH_ID`: The Stream offset or Airflow Dag Run ID.
* `PIPELINE_RUN_ID`: UUID representing the specific execution thread.
* `RECORD_CHECKSUM`: `MD5()` hash of all descriptive columns to detect changes instantly.
* `VERSION_NUMBER`: Incrementing integer for SCD2 changes.
