# Module 5: Enterprise Watermark & Checkpoint Framework

## Overview
This module completes the Control Plane of the CDC Framework by implementing an independent State Management system (Checkpoints and Watermarks) using Snowflake Stored Procedures.

## Key Features
* **Source of Truth:** While Snowflake Streams track offset logic implicitly, the Watermark table explicitly stores the `High_Watermark` timestamp of the last successful extraction.
* **Batch Lineage:** Every single execution is logged in `TB_BATCH_CONTROL` with a unique `Batch_ID`. This ID is injected into the Silver `MERGE` statements as the `BATCH_ID` audit column.
* **Failure Resilience:** The Checkpoint procedure (`SP_ROLLBACK_CHECKPOINT`) guarantees that failed executions do not advance the global watermark. When the pipeline restarts, it automatically recalculates the exact same extraction bounds (Low Watermark -> Next High Watermark).

## Transaction Design
The Checkpoint creation (`SP_CREATE_CHECKPOINT`), data processing (`MERGE`), and Checkpoint commit (`SP_UPDATE_CHECKPOINT`) must be wrapped within a single logical flow. If the `MERGE` fails, the `CATCH` block of the orchestrating procedure will fire `SP_ROLLBACK_CHECKPOINT`.

## Deliverables Checklist
- [x] Design Summary & Architecture Document
- [x] Metadata Control Tables
- [x] Checkpoint/Watermark Stored Procedures
- [x] Validation Tests (Initial, Incremental, Failures, Restarts)
