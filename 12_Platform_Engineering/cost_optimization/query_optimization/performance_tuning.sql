-- ==============================================================================
-- Enterprise Query Performance Optimization
-- Clustering, Search Optimization, and Caching strategies.
-- ==============================================================================

USE ROLE SYSADMIN;

-- ==============================================================================
-- 1. CLUSTERING KEYS
-- Only applied to large tables (> 1TB) with clear filter/join patterns.
-- DO NOT cluster small tables; the reclustering DML cost outweighs any scan savings.
-- ==============================================================================

-- FCT_SALES: Always filtered by SALE_DATE and joined on STORE_ID
-- Clustering reduces partition scans from 100% to ~5% for date-range queries.
ALTER TABLE OMNIRETAIL.GOLD.FCT_SALES 
  CLUSTER BY (SALE_DATE, STORE_ID);

-- FCT_INVENTORY: Always filtered by SNAPSHOT_DATE
ALTER TABLE OMNIRETAIL.GOLD.FCT_INVENTORY 
  CLUSTER BY (SNAPSHOT_DATE, PRODUCT_ID);

-- ==============================================================================
-- 2. SEARCH OPTIMIZATION SERVICE
-- Applied to tables where users run ad-hoc EQUALITY or IN() filters
-- on high-cardinality columns (e.g., ORDER_ID, CUSTOMER_EMAIL).
-- DO NOT enable on tables already covered by clustering keys on the same column.
-- ==============================================================================

-- DIM_CUSTOMER: Analysts frequently search by EMAIL or CUSTOMER_ID
ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER
  ADD SEARCH OPTIMIZATION ON EQUALITY(CUSTOMER_ID, EMAIL);

-- ==============================================================================
-- 3. CACHING STRATEGY
-- Result Cache: Automatically enabled by Snowflake for identical queries within 24h.
-- Metadata Cache: Queries like COUNT(*), MIN(), MAX() are served from metadata.
-- Warehouse Cache: SSD-based cache on the warehouse. Keep BI warehouse warm (300s).
-- Strategy: We keep BI_WH auto_suspend at 300s to preserve the SSD cache
--           between rapid analyst queries, while ETL warehouses use 60s.
-- ==============================================================================

-- ==============================================================================
-- 4. TIME TRAVEL & STORAGE OPTIMIZATION
-- Bronze/Silver: 90-day retention (raw data is irreplaceable).
-- Gold: 1-day retention (fully reproducible via dbt Cloud).
-- Transient tables: Used for staging/scratch data (0 Fail-safe = cheaper).
-- ==============================================================================

ALTER DATABASE PROD_BRONZE_DB SET DATA_RETENTION_TIME_IN_DAYS = 90;
ALTER DATABASE PROD_SILVER_DB SET DATA_RETENTION_TIME_IN_DAYS = 90;
ALTER DATABASE PROD_GOLD_DB   SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- Staging tables that are rebuilt every run should be TRANSIENT (no Fail-safe cost)
-- CREATE TRANSIENT TABLE OMNIRETAIL.SILVER.STG_ORDERS_TEMP (...);
