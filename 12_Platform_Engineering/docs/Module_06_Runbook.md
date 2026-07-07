# Operational Runbook: Cost Optimization

## Common Production Issues

### 1. Warehouse Left Running Overnight
**Symptom:** The FinOps dashboard shows `PROD_BI_WH` consumed 48 credits overnight despite no users.
**Root Cause:** `AUTO_SUSPEND` was set too high (e.g., 3600s) or a stuck Power BI query kept the warehouse alive.
**Resolution:**
Run Query 4 from `finops_dashboard_queries.sql` (Warehouse Utilization). If `avg_queries_running` is near 0 during overnight hours, reduce `AUTO_SUSPEND` to 300s or less. Kill stuck queries using `SELECT SYSTEM$CANCEL_ALL_QUERIES(...)`.

### 2. Large Cross-Joins Burning Credits
**Symptom:** A single query consumed 15 credits and ran for 45 minutes.
**Root Cause:** A developer accidentally performed a `CROSS JOIN` between two large tables.
**Resolution:**
Run Query 1 from `finops_dashboard_queries.sql` (Top Expensive Queries). The `partition_scan_pct` column will show 100%, confirming a full scan. Enforce `STATEMENT_TIMEOUT_IN_SECONDS` (already hardcoded in our warehouses) to auto-kill runaway queries.

### 3. Clustering Key Misconfiguration
**Symptom:** Monthly reclustering DML credits are higher than the query performance savings.
**Root Cause:** A clustering key was applied to a small table (< 100GB) that doesn't benefit.
**Resolution:**
Only cluster tables > 1TB with clear, predictable filter patterns. Drop the clustering key: `ALTER TABLE ... DROP CLUSTERING KEY;`.
