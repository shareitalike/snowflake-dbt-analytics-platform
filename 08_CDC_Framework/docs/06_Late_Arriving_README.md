# Module 6: Enterprise Late Arriving Data Framework

## Overview
This module completes the CDC Data Pipeline by explicitly handling the most common failure state in distributed microservice architectures: **Out-of-Order Data Delivery**. 

By injecting proactive logic directly into the Task DAG (Module 3) and utilizing the Idempotent MERGE patterns (Module 4), we completely eliminate Foreign Key violations caused by Fact payloads arriving before their associated Dimension payloads.

## Key Features
* **Inferred Members (Ghost Records):** If an Order arrives for a `Customer_ID` that does not exist in the Silver layer, `SP_INFER_LATE_CUSTOMERS` proactively inserts a temporary "Ghost" record with placeholder values. This allows the Order to merge successfully without failing referential integrity constraints.
* **SCD2 Self-Correction:** When the actual Customer payload finally arrives, the standard CDC `MERGE` automatically expires the Ghost record and instantiates the real customer data as the active version.
* **Task Orchestration Integration:** The inference stored procedures are wrapped in `TSK_CDC_INFER_GHOSTS` and injected into the DAG immediately *before* the Fact tasks, guaranteeing dimensions are scaffolded just in time.

## Deliverables Checklist
- [x] Design Summary & Strategy Document
- [x] Ghost Dimension Stored Procedures (`SP_INFER_LATE_CUSTOMERS`, `SP_INFER_LATE_PRODUCTS`)
- [x] Validation Tests (Fact & Dimension Reconciliation)
