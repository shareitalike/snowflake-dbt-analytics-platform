# CASE STUDY 5: Monthly FinOps Report — July 2025
## Executive Summary
Total Snowflake spend in July was **$4,230** against a budget of **$3,500**. This report identifies the root causes, actions taken, and projected savings for August.

## Credit Consumption Breakdown

| Warehouse | Credits | Cost ($3/cr) | % of Total | Trend |
|-----------|---------|-------------|-----------|-------|
| PROD_TRANSFORM_WH | 340 | $1,020 | 32% | 🔴 +180% vs June |
| PROD_DBT_WH | 363 | $1,089 | 34% | 🟡 Flat |
| PROD_BI_WH | 420 | $1,260 | 40% | 🟡 +10% vs June |
| PROD_INGEST_WH | 45 | $135 | 4% | 🟢 Flat |
| PROD_ADMIN_WH | 8 | $24 | <1% | 🟢 Flat |
| **Storage** | — | $702 | — | 🟡 +5% vs June |
| **Total** | **1,176** | **$4,230** | **100%** | **🔴 +21% over budget** |

## Root Cause Analysis

### Issue 1: TRANSFORM_WH Spike ($765 overspend)
A developer ran full-table MERGEs without stream filtering on July 14–16.
**Action:** Resource Monitor upgraded from NOTIFY to SUSPEND at 100%. Stream validation enforced in Airflow operator. (See Case Study 2)
**Projected Savings:** $765/month

### Issue 2: DBT_WH Running Full Refreshes ($1,017 potential savings)
`fct_sales` was materialized as `table` instead of `incremental`, rebuilding 500M rows daily.
**Action:** Converted to `incremental` with `merge` strategy. (See Case Study 3)
**Projected Savings:** $1,017/month

### Issue 3: BI_WH Idle Overnight ($180 waste)
Warehouse stayed active from 11 PM to 6 AM with zero queries running.
**Action:** Reduced `AUTO_SUSPEND` from 600s to 300s. Verified no scheduled Power BI refreshes occur overnight.
**Projected Savings:** $180/month

## August Forecast

| Warehouse | July Actual | August Projected | Savings |
|-----------|-----------|-----------------|---------|
| PROD_TRANSFORM_WH | $1,020 | $255 | $765 |
| PROD_DBT_WH | $1,089 | $72 | $1,017 |
| PROD_BI_WH | $1,260 | $1,080 | $180 |
| Other | $159 | $159 | $0 |
| Storage | $702 | $680 | $22 |
| **Total** | **$4,230** | **$2,246** | **$1,984 (47% reduction)** |

*"I run a monthly FinOps review where I query WAREHOUSE_METERING_HISTORY and QUERY_HISTORY to identify cost anomalies. In one month, I identified three issues—an accidental full-table MERGE, a non-incremental dbt model, and an idle BI warehouse—that together saved nearly $2,000/month. The key insight is that cost optimization is not a one-time activity; it's an ongoing operational discipline."*
