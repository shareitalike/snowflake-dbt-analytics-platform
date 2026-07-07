# Cost Optimization & Performance Engineering
## Module 06 - Design Summary

### FinOps Strategy: Right-Size, Right-Time, Right-Policy
Our FinOps approach is based on three principles:
1. **Right-Size:** Each warehouse is purpose-built for its workload. Ingestion is I/O-bound (XSMALL). CDC MERGE is CPU-bound (MEDIUM). dbt compilation is memory-intensive (LARGE). BI requires concurrency (MEDIUM with multi-cluster scaling up to 4).
2. **Right-Time:** `AUTO_SUSPEND` is tuned per warehouse. ETL warehouses suspend aggressively (60-120s) because batches are predictable. The BI warehouse keeps warm (300s) to preserve the SSD Warehouse Cache for rapid analyst queries.
3. **Right-Policy:** Multi-cluster scaling policies differ. ETL uses `ECONOMY` (minimizes clusters, saves credits). BI uses `STANDARD` (spins up clusters immediately for concurrency).

### Query Performance Engineering
We employ three distinct optimization techniques depending on query patterns:
- **Clustering Keys:** Applied ONLY to large Gold tables (> 1TB) with clear filter predicates (`SALE_DATE`, `STORE_ID`). Clustering reduces micro-partition scans from 100% to ~5% for typical date-range queries. We never cluster small tables because the reclustering DML cost exceeds the scan savings.
- **Search Optimization Service:** Applied to high-cardinality equality lookups (`CUSTOMER_ID`, `EMAIL`) where clustering is not appropriate. This is ideal for ad-hoc analyst searches.
- **Caching:** We leverage all three Snowflake caches. Result Cache is automatic for identical queries. Metadata Cache handles `COUNT(*)` and `MIN/MAX()`. Warehouse (SSD) Cache is preserved by keeping the BI warehouse warm.

### Storage Cost Optimization
We implement differentiated Time Travel retention:
- **Bronze/Silver:** 90-day retention (raw data is irreplaceable if corrupted).
- **Gold:** 1-day retention (fully reproducible via `dbt build`; no need to pay for 90 days).
- **Staging Tables:** Created as `TRANSIENT` to eliminate 7-day Fail-safe storage costs entirely.
