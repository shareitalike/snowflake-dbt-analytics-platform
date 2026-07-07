# Operational Runbook: Metrics & Monitoring

## Common Production Issues

### 1. Alert Fatigue
**Symptom:** The Data Engineering Slack channel receives 500 alerts a day for "Null Value Detected in Optional Column", causing engineers to ignore the channel. When a critical pipeline fails, nobody notices.
**Root Cause:** Alert thresholds were set too aggressively on non-critical Data Quality metrics.
**Resolution:** 
1. The `AlertFramework` enforces severity routing (`CRITICAL`, `WARNING`, `INFO`). 
2. Route `CRITICAL` (Pipeline Fails, Freshness SLA Breaches) to PagerDuty. 
3. Route `WARNING` (DQ Degradation, DLQ Volume Spikes) to a daily digest email or secondary Slack channel.
4. Silence `INFO` alerts and reserve them for Dashboard visualizations only.

### 2. Warehouse Saturation (Queueing)
**Symptom:** `WarehouseMetrics` reports that `Queue Time` is exceeding `Execution Time`. Pipelines are breaching SLA despite processing small data volumes.
**Root Cause:** Too many concurrent tasks are assigned to a single `XSMALL` warehouse, exceeding the max concurrency limit (usually 8 queries per cluster).
**Resolution:**
1. Use the Platform Health Dashboard to identify the concurrent spike.
2. Enable Multi-Cluster Warehouses (MCW) on the ingestion warehouse to automatically scale out up to 5 clusters during peaks.
3. Alternatively, route heavy analytical models to a separate warehouse.

### 3. Credit Spikes (FinOps)
**Symptom:** The `Warehouse Cost Threshold` alert triggers. A specific Snowpark pipeline consumed 50 credits in one day.
**Root Cause:** A pipeline used a nested `LATERAL FLATTEN` on a multi-gigabyte JSON payload without filtering, causing massive partition explosion and keeping the warehouse active for 4 hours.
**Resolution:**
Identify the exact Query ID using the `PipelineMetrics` view. Refactor the Snowpark job to prune partitions before flattening (as documented in Module 6). Adjust the `Auto Suspend` setting on the warehouse to 60 seconds to prevent idle billing.
