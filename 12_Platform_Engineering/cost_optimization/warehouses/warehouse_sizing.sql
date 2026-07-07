-- ==============================================================================
-- Enterprise Warehouse Sizing & FinOps Configuration
-- Each warehouse is purpose-built for its workload profile.
-- ==============================================================================

USE ROLE SYSADMIN;

-- 1. INGEST_WH: Handles Snowpipe and COPY INTO operations
--    Rationale: Ingestion is I/O-bound (not CPU-bound). XSMALL is sufficient.
--    Auto-suspend aggressive (60s) because ingestion bursts are short.
CREATE OR REPLACE WAREHOUSE PROD_INGEST_WH
  WAREHOUSE_SIZE   = 'XSMALL'
  AUTO_SUSPEND     = 60
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 2
  SCALING_POLICY   = 'ECONOMY'
  STATEMENT_TIMEOUT_IN_SECONDS = 1800 -- 30 min max (ingestion shouldn't take longer)
  COMMENT = 'FinOps: Purpose-built for Snowpipe ingestion. Economy scaling to minimize credits.';

-- 2. TRANSFORM_WH: Handles CDC MERGE and Snowpark processing
--    Rationale: MERGE is compute-heavy. MEDIUM handles high-volume CDC.
--    Auto-suspend moderate (120s) because CDC batches arrive in clusters.
CREATE OR REPLACE WAREHOUSE PROD_TRANSFORM_WH
  WAREHOUSE_SIZE   = 'MEDIUM'
  AUTO_SUSPEND     = 120
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  SCALING_POLICY   = 'STANDARD'
  STATEMENT_TIMEOUT_IN_SECONDS = 3600 -- 1 hour max
  COMMENT = 'FinOps: Purpose-built for CDC MERGE and Snowpark. Standard scaling for throughput.';

-- 3. DBT_WH: Dedicated to dbt Cloud model compilation and execution
--    Rationale: dbt runs 200+ models sequentially. LARGE handles the volume.
--    Auto-suspend moderate (120s) because dbt runs are long but predictable.
CREATE OR REPLACE WAREHOUSE PROD_DBT_WH
  WAREHOUSE_SIZE   = 'LARGE'
  AUTO_SUSPEND     = 120
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 1  -- Single cluster; dbt models run sequentially, not concurrently
  SCALING_POLICY   = 'ECONOMY'
  STATEMENT_TIMEOUT_IN_SECONDS = 7200 -- 2 hours max (for full model rebuild)
  COMMENT = 'FinOps: Purpose-built for dbt Cloud. Single cluster since dbt threads are sequential SQL.';

-- 4. BI_WH: Serves Power BI analyst queries
--    Rationale: Analysts expect sub-second responses. Keep warm (300s suspend).
--    Multi-cluster to handle concurrent dashboards at 9:00 AM login spike.
CREATE OR REPLACE WAREHOUSE PROD_BI_WH
  WAREHOUSE_SIZE   = 'MEDIUM'
  AUTO_SUSPEND     = 300
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 4
  SCALING_POLICY   = 'STANDARD'
  STATEMENT_TIMEOUT_IN_SECONDS = 600 -- 10 min max (BI queries should never run longer)
  COMMENT = 'FinOps: Purpose-built for Power BI. Standard scaling for concurrency spikes.';

-- 5. ADMIN_WH: Lightweight warehouse for Terraform, metadata, and monitoring queries
CREATE OR REPLACE WAREHOUSE PROD_ADMIN_WH
  WAREHOUSE_SIZE   = 'XSMALL'
  AUTO_SUSPEND     = 60
  AUTO_RESUME      = TRUE
  INITIALLY_SUSPENDED = TRUE
  STATEMENT_TIMEOUT_IN_SECONDS = 300
  COMMENT = 'FinOps: Minimal compute for admin, metadata, and Terraform operations.';
