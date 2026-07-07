-- ==============================================================================
-- CASE STUDY 1: Slow Query Optimization (Query Profile Analysis)
-- ==============================================================================
-- SCENARIO: The Finance team reported that their monthly revenue reconciliation
-- query was taking 12 minutes and consuming 8 credits on PROD_BI_WH (MEDIUM).
-- We used the Snowflake Query Profile to diagnose the issue.
--
-- ORIGINAL QUERY (BEFORE):
-- Runtime: 12 minutes 14 seconds
-- Credits: 8.2
-- Partitions Scanned: 4,200 / 4,200 (100% full table scan)
-- Bytes Spilled to Remote: 14 GB (warehouse too small for the sort)
-- ==============================================================================

-- STEP 1: Reproduce the slow query
-- SELECT
--     s.STORE_ID,
--     p.PRODUCT_CATEGORY,
--     SUM(f.SALE_AMOUNT) AS total_revenue,
--     COUNT(DISTINCT f.CUSTOMER_ID) AS unique_customers
-- FROM OMNIRETAIL.GOLD.FCT_SALES f
-- JOIN OMNIRETAIL.GOLD.DIM_STORE s ON f.STORE_KEY = s.STORE_KEY
-- JOIN OMNIRETAIL.GOLD.DIM_PRODUCT p ON f.PRODUCT_KEY = p.PRODUCT_KEY
-- WHERE f.SALE_DATE BETWEEN '2025-01-01' AND '2025-12-31'
-- GROUP BY 1, 2
-- ORDER BY total_revenue DESC;

-- STEP 2: Query Profile Analysis (What we observed)
-- Node 1: TableScan on FCT_SALES -> 100% partition scan (NO pruning)
-- Node 3: Sort -> "Bytes Spilled to Remote Storage: 14 GB"
--   This means the MEDIUM warehouse ran out of local SSD cache and had to
--   spill the sort operation to remote S3, causing massive latency.
--
-- ROOT CAUSE IDENTIFIED:
--   1. FCT_SALES has no clustering key. Date-range filter cannot prune partitions.
--   2. The MEDIUM warehouse is too small for a full-year sort on 500M rows.

-- STEP 3: Fix Applied
ALTER TABLE OMNIRETAIL.GOLD.FCT_SALES CLUSTER BY (SALE_DATE, STORE_ID);
-- We do NOT upsize the warehouse. We fix the query pattern instead.

-- STEP 4: Results (AFTER clustering settled, ~24 hours later)
-- Runtime: 18 seconds (down from 12 minutes — 40x improvement)
-- Credits: 0.3 (down from 8.2 — 96% reduction)
-- Partitions Scanned: 210 / 4,200 (5% — excellent pruning)
-- Bytes Spilled to Remote: 0 GB (data fits in cache after pruning)

-- ==============================================================================
-- "The first instinct of a junior engineer is to upsize the warehouse.
--  A senior engineer analyzes the Query Profile, identifies the full table scan,
--  and applies a clustering key instead. This solves the problem permanently
--  and actually REDUCES cost."
-- ==============================================================================
