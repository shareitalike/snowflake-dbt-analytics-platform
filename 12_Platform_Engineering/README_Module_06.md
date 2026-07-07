# Phase 12 - Module 6: Enterprise Cost Optimization & Performance Engineering

This module introduces a rigorous FinOps discipline across the entire Snowflake and Airflow platform.

## Deliverables Checklist

- [x] **Warehouse Sizing:** Created `warehouse_sizing.sql` defining purpose-built warehouses with explicit FinOps rationale (Right-Size, Right-Time, Right-Policy).
- [x] **FinOps Dashboard:** Created `finops_dashboard_queries.sql` with 5 production-ready queries: Top Expensive Queries, Credit by Warehouse, Credit by Team/Domain, Warehouse Utilization, and Storage Breakdown.
- [x] **Query Optimization:** Created `performance_tuning.sql` implementing Clustering Keys (for range scans), Search Optimization Service (for equality lookups), and Time Travel optimization across database layers.
- [x] **Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_06_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_06_Runbook.md).md).

## Key Architecture Decision
| Warehouse | Size | Auto-Suspend | Scaling | Rationale |
|-----------|------|-------------|---------|-----------|
| INGEST_WH | XSMALL | 60s | Economy | I/O-bound Snowpipe loads |
| TRANSFORM_WH | MEDIUM | 120s | Standard | CPU-bound CDC MERGE |
| DBT_WH | LARGE | 120s | Economy | Memory for SQL compilation |
| BI_WH | MEDIUM | 300s | Standard | Concurrency + SSD cache warmth |
| ADMIN_WH | XSMALL | 60s | N/A | Terraform and metadata |
