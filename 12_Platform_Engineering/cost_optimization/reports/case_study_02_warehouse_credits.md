# CASE STUDY 2: Warehouse Credit Over-Consumption
## Scenario
During a monthly FinOps review, we discovered that `PROD_TRANSFORM_WH` had consumed **340 credits** in July, far exceeding its 100-credit Resource Monitor budget. The monitor had been set to `NOTIFY` at 100% but not `SUSPEND`, allowing the warehouse to keep running.

## Root Cause Analysis

### Step 1: Identify the spike window
```sql
SELECT 
    DATE_TRUNC('day', start_time) AS usage_date,
    ROUND(SUM(credits_used), 2) AS daily_credits
FROM snowflake.account_usage.warehouse_metering_history
WHERE warehouse_name = 'PROD_TRANSFORM_WH'
  AND start_time >= '2025-07-01'
GROUP BY 1 ORDER BY 1;
```
**Finding:** July 14–16 consumed 180 credits (3 days = 53% of the monthly total).

### Step 2: Find the offending queries
```sql
SELECT query_id, user_name, total_elapsed_time/1000 AS seconds, query_text
FROM snowflake.account_usage.query_history
WHERE warehouse_name = 'PROD_TRANSFORM_WH'
  AND start_time BETWEEN '2025-07-14' AND '2025-07-17'
ORDER BY total_elapsed_time DESC LIMIT 10;
```
**Finding:** A developer ran `MERGE INTO SILVER.CUSTOMERS` **without a stream filter**, causing a full-table MERGE of 120M rows instead of the delta (~5,000 rows). This ran 3 times because retries were configured.

### Step 3: Fix Applied
1. **Immediate:** Added `SUSPEND_TRIGGERS = [100]` to the Resource Monitor in Terraform. This ensures the warehouse hard-stops at budget.
2. **Preventive:** Updated the `EnterpriseSnowflakeOperator` to always check `SYSTEM$STREAM_HAS_DATA()` before executing any MERGE.
3. **Detective:** Added the query to our Airflow `enterprise_alert_router` to send a Slack alert if any single query exceeds 30 minutes on this warehouse.

## Results

| Metric | Before | After |
|--------|--------|-------|
| July Credits | 340 | 85 |
| Full-Table MERGEs | 3 (accidental) | 0 |
| Resource Monitor Action | Notify Only | Suspend at 100% |
| Monthly Cost (at $3/credit) | $1,020 | $255 |
| **Savings** | | **$765/month (75%)** |
