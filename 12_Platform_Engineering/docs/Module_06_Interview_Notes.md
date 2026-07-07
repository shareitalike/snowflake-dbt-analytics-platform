# Interview Notes: Snowflake FinOps & Performance

## Q: How do you optimize Snowflake costs?
**A:** "I approach FinOps on three axes. First, **Right-Sizing**: I build purpose-specific warehouses. Ingestion is I/O-bound, so XSMALL is sufficient. dbt needs memory for SQL compilation, so LARGE is justified. Second, **Auto-Suspend Tuning**: ETL warehouses suspend in 60 seconds because batch windows are predictable. The BI warehouse stays warm at 300 seconds to preserve the SSD Warehouse Cache for rapid analyst queries. Third, **Statement Timeouts**: Every warehouse has a hardcoded `STATEMENT_TIMEOUT_IN_SECONDS` via Terraform, guaranteeing no runaway query can silently burn credits over the weekend."

## Q: When do you use Clustering Keys vs Search Optimization Service?
**A:** "Clustering Keys and Search Optimization solve fundamentally different problems. **Clustering** is for range-based scans on large tables (> 1TB). If analysts always filter by `SALE_DATE BETWEEN X AND Y`, clustering by `SALE_DATE` groups related micro-partitions together, reducing scans from 100% to ~5%. **Search Optimization** is for equality lookups on high-cardinality columns. If an analyst searches `WHERE CUSTOMER_ID = 'ABC-123'`, Snowflake builds a skip-index that directly locates the micro-partition. I would never apply both to the same column—that would be redundant and wasteful."

## Q: How do you monitor warehouse utilization?
**A:** "I built a FinOps monitoring dashboard using `SNOWFLAKE.ACCOUNT_USAGE` views. The most impactful query tracks daily credit consumption per warehouse (`WAREHOUSE_METERING_HISTORY`). A second query identifies idle warehouses by checking `avg_queries_running` in `WAREHOUSE_LOAD_HISTORY`. If a warehouse has been running but processing near-zero queries, that's immediate waste. A third query breaks down storage costs by Active, Time Travel, and Fail-safe to identify databases where retention settings are too generous."

## Q: How do you reduce storage costs?
**A:** "I implement differentiated Time Travel retention. Bronze gets 90 days because raw data from the source system is irreplaceable. Gold gets 1 day because dbt can fully reproduce it with a single `dbt build`. Staging tables are created as `TRANSIENT` to completely eliminate the 7-day Fail-safe cost, since they are ephemeral and rebuilt every pipeline run."
