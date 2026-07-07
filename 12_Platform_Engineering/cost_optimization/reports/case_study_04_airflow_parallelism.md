# CASE STUDY 4: Airflow DAG Bottleneck — Serial to Parallel Optimization
## Scenario
The `enterprise_master_orchestrator_dag` was processing 6 domain pipelines (Sales, Inventory, Finance, Marketing, Customer, Support) **sequentially**. Total DAG runtime was 3 hours 40 minutes. The SLA target was 2 hours.

## Before (Sequential Execution)
```
kickoff -> sales_pipeline -> inventory_pipeline -> finance_pipeline -> 
marketing_pipeline -> customer_pipeline -> support_pipeline -> end
```
**Total Runtime:** 3h 40m | **SLA Target:** 2h | **Status:** ❌ SLA MISS

### Root Cause
The 6 domain pipelines had **zero data dependency** between them. Sales does not depend on Inventory. Finance does not depend on Marketing. They were sequentially chained because the original engineer used a simple linear task dependency (`>>`).

## After (Parallel Execution with TaskGroups and Pools)
```python
from airflow.utils.task_group import TaskGroup

with TaskGroup('domain_pipelines') as parallel_domains:
    sales = build_domain_taskgroup('sales')
    inventory = build_domain_taskgroup('inventory')
    finance = build_domain_taskgroup('finance')
    marketing = build_domain_taskgroup('marketing')
    customer = build_domain_taskgroup('customer')
    support = build_domain_taskgroup('support')

# All 6 run in parallel, gated by a Snowflake pool to limit concurrency
kickoff >> parallel_domains >> post_processing >> end
```

### Pool Configuration (Prevent Warehouse Overload)
```python
# airflow.cfg or Airflow UI -> Admin -> Pools
# Pool Name: snowflake_concurrent_pool
# Slots: 4  (max 4 domains run simultaneously to prevent Snowflake queuing)
```

## Results

| Metric | Sequential | Parallel (4 slots) | Improvement |
|--------|-----------|-------------------|-------------|
| Total DAG Runtime | 3h 40m | 58 min | **3.8x faster** |
| SLA Status | ❌ MISS | ✅ MET | Fixed |
| Snowflake Concurrency | 1 query at a time | 4 concurrent | Balanced |
| Airflow Worker Slots Used | 1 | 4 (pool-limited) | Controlled |

*"Independent pipelines should never run sequentially. I use Airflow TaskGroups to fan-out parallel execution. But unbounded parallelism is equally dangerous—it can overwhelm Snowflake with queued queries. I use Airflow Pools to cap concurrency at 4 slots, balancing throughput against warehouse queuing."*
