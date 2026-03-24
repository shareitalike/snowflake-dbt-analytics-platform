/* ==============================================================================
 * FILE: 02_warehouses.sql
 * PHASE: 06 - Snowflake Platform
 * 
 * EXPLANATION: Provisions isolated virtual compute warehouses sized specifically for distinct workloads, attaching them to their respective resource monitors.
 * DESIGN DECISIONS: Uses AUTO_SUSPEND of 60 seconds (default) for most workloads. Uses a multi-cluster warehouse (WH_BI) for Power BI to handle high concurrency. Uses INITIALLY_SUSPENDED = TRUE to avoid instant compute charges.
 * WHY: Workload isolation ensures that massive dbt transformations do not starve business analysts of compute resources. Multi-cluster scaling gracefully handles Monday-morning BI dashboard spikes without manual intervention.
 * ============================================================================== */

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS WH_INGEST
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = RM_INGESTION
    COMMENT = 'Dedicated warehouse for Snowpipe and Airflow polling.';

CREATE WAREHOUSE IF NOT EXISTS WH_TRANSFORM
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated warehouse for Snowpark Python logic.';

CREATE WAREHOUSE IF NOT EXISTS WH_DBT
    WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = RM_DBT_TRANSFORM
    COMMENT = 'Dedicated warehouse for dbt Cloud SQL transformations.';

CREATE WAREHOUSE IF NOT EXISTS WH_BI
    WAREHOUSE_SIZE = 'SMALL'
    MAX_CLUSTER_COUNT = 5
    MIN_CLUSTER_COUNT = 1
    SCALING_POLICY = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = RM_BI_REPORTING
    COMMENT = 'Multi-cluster warehouse for concurrent Power BI queries.';

CREATE WAREHOUSE IF NOT EXISTS WH_ADHOC
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    RESOURCE_MONITOR = RM_ADHOC
    COMMENT = 'Ad-hoc queries for Data Analysts.';

CREATE WAREHOUSE IF NOT EXISTS WH_ADMIN
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Administrative tasks and DDL execution.';
