# Module 4: Enterprise MERGE Framework

## Overview
This module completes the Phase 08 CDC Framework by providing the execution engine that consumes the Streams. By implementing native Snowflake Stored Procedures that execute highly complex `MERGE` statements, we decouple the extraction (Snowpipe) from the transformation logic.

## Key Features
* **SCD Type 2 Dimension tracking**: Customer, Product, Store, and Employee dimensions track historical versions automatically using Effective (`VALID_FROM`) and Expiry (`VALID_TO`) dates.
* **Idempotent Operations**: Built with `QUALIFY ROW_NUMBER() = 1` and `CHECKSUM` validations to ensure that if a task fails or repeats, the target data remains perfectly consistent.
* **Late-Arriving Data Resilience**: Explicit timestamp checks (`src.updated_at > tgt.updated_at`) guarantee that out-of-order payloads do not overwrite newer data.

## Performance Optimization 
* **Pruning**: We do not filter the `USING` stream query with complex WHERE clauses; Streams are native metadata pointers. The processing burden is shifted entirely to the `MERGE ... ON` clause.
* **Clustering**: The Silver target tables (e.g., `TB_CUSTOMER_DIM`) should eventually be clustered by `business_key` if `MERGE` performance degrades.
* **Warehouse**: Executed on `WH_TRANSFORM`.

## Deliverables Checklist
- [x] Folder Structure
- [x] MERGE Design Strategy
- [x] SCD1 and SCD2 logic
- [x] Transactional MERGE logic
- [x] Audit Columns framework
- [x] Validation Views
- [x] Production Runbook and Test Cases
