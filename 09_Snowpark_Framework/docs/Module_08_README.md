# Phase 09 - Module 8: Enterprise Audit & Metadata Framework

This module enforces Enterprise Data Governance by automatically capturing execution telemetry, structural metadata, and bi-modal directional lineage across the entire platform.

## Deliverables Checklist

- [x] **Design Summary:** Documented the strategy for Operational Metadata, Lineage, and Execution Tracking.
- [x] **Repository Structure:** Created `audit_metadata/` with `audit`, `metadata`, and `lineage` subdirectories.
- [x] **Audit Framework:** Implemented the `ExecutionTracker` context manager to guarantee telemetry flushes (Rows Read/Written, Query IDs, Status) on both success and failure.
- [x] **Metadata Framework:** Implemented `SchemaMetadata` to explicitly track and log structural drift (missing/unexpected columns) over time.
- [x] **Bi-Modal Lineage Framework:** Implemented `LineageTracker` to build directional graphs for both:
    - **Technical Lineage**: `Shopify -> S3 -> Snowpipe -> Bronze -> Stream -> Task -> Silver -> dbt -> Gold -> PowerBI`
    - **Business Lineage**: `Shopify (Orders) -> Sales Fact -> GMV KPI`
- [x] **Unit Tests:** `test_audit_metadata.py` validating Context Managers and both lineage methodologies.
- [x] **Operational Runbook:** Documented troubleshooting for Zombie Pipelines and Orphaned Lineage.

## Usage Example (Lineage Tracker)

```python
from src.audit_metadata.lineage.lineage_tracker import LineageTracker, LineageNode

tracker = LineageTracker(session, logger)

# 1. Technical Lineage Registration
bronze = LineageNode("TB_ORDERS_RAW", "TABLE", "BRONZE")
silver = LineageNode("TB_ORDERS_CLEAN", "TABLE", "SILVER")
tracker.register_technical_dependency(bronze, silver, pipeline_id="PIPE_SILVER_ORDERS")

# 2. Business Lineage Registration
gold_sales = LineageNode("TB_SALES_FACT", "TABLE", "GOLD")
gmv_kpi = LineageNode("GMV_KPI", "KPI", "BUSINESS_METRIC")
tracker.register_business_dependency(gold_sales, gmv_kpi, business_context="Q3_FINANCE_REPORTING")

# Flush to Control Tables
tracker.flush_lineage()
```
