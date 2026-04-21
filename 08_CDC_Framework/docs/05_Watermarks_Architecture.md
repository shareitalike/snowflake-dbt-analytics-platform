# Module 5: Enterprise Watermark & Checkpoint Architecture

## 1. Design Summary

### Why Watermarking?
While Snowflake Streams elegantly handle CDC offset management on the Bronze tables, they are vulnerable to metadata loss (e.g., if the base table is recreated, the stream goes stale and loses its offset). A robust Watermark & Checkpoint Framework acts as the independent "Source of Truth" for data processing state. By persisting the highest successfully processed timestamp (the High Watermark), we can safely replay historical data or recover from catastrophic stream loss without relying on Snowflake-internal stream metadata.

### High Watermark vs Low Watermark
* **High Watermark:** The maximum `source_updated_at` timestamp that was successfully committed to the target table in the *last* batch. 
* **Low Watermark:** The maximum timestamp from the *previous* batch. The current batch processes all records where `source_updated_at > Low Watermark AND source_updated_at <= High Watermark`.

### Checkpoint Strategy
Checkpoints act as transactional save-points. Before a CDC batch runs, a checkpoint is created with status `STARTED`. When the batch commits, the checkpoint is updated to `COMPLETED`. If a failure occurs, the checkpoint remains `STARTED` or `FAILED`.

### Restartability & Recovery
If a pipeline crashes mid-execution (e.g., a warehouse timeout), the Checkpoint Framework identifies the `FAILED` batch. The system automatically reads the last successful High Watermark, resets the bounds, and re-executes the exact same batch of data.

### Idempotency
Because the framework ties the extraction bounds directly to the Batch ID, re-running a batch is guaranteed to extract the exact same slice of data. When combined with the Idempotent `MERGE` logic from Module 4, duplicate processing is completely nullified.

## 2. Folder Structure
The implementation for Module 5 is located at:
```text
08_CDC_Framework/
├── 05_Watermarks_Architecture.md
├── src/
│   ├── 11_watermark_metadata_tables.sql  # Control schema definition
│   ├── 12_watermark_procedures.sql       # Reusable checkpoint/watermark logic
├── tests/
│   └── 04_watermark_tests.sql            # Validation and test cases
├── 05_Watermarks_README.md
├── 05_Watermarks_Operational_Runbook.md
```
