-- ==============================================================================
-- 19_monitoring_procedures.sql
-- Description: Stored procedures to evaluate metrics and generate Alerts
-- Phase: 08 - CDC Framework (Module 8)
-- ==============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_OBSERVABILITY;

-- ------------------------------------------------------------------------------
-- 1. EVALUATE PIPELINE SLA BREACHES
-- ------------------------------------------------------------------------------
-- This procedure runs hourly to sweep the VW_PIPELINE_FRESHNESS_SLA view 
-- and push critical breaches into the Alert Queue for external notification.
CREATE OR REPLACE PROCEDURE SP_EVALUATE_SLA_BREACHES()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO TB_ALERT_QUEUE (Alert_Type, Severity, Pipeline_ID, Alert_Message)
    SELECT 
        'SLA_BREACH',
        'CRITICAL',
        Pipeline_ID,
        'Pipeline SLA breached. Data latency is ' || Data_Latency_Minutes || ' minutes.'
    FROM VW_PIPELINE_FRESHNESS_SLA
    WHERE SLA_Status = 'BREACH'
      -- Prevent spamming: only alert if an active alert doesn't already exist
      AND Pipeline_ID NOT IN (
          SELECT Pipeline_ID FROM TB_ALERT_QUEUE 
          WHERE Alert_Type = 'SLA_BREACH' AND Is_Resolved = FALSE
      );

    RETURN 'SLA Evaluation Completed';
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. ROLLUP DAILY METRICS (FIX P2-008: converted to MERGE for idempotency)
-- ------------------------------------------------------------------------------
-- Runs nightly to aggregate granular TB_BATCH_CONTROL logs into a daily summary.
-- Using MERGE ensures that a retry (Airflow re-run, manual execution) produces
-- 0 rows inserted on the second pass rather than duplicating dashboard data.
CREATE OR REPLACE PROCEDURE SP_ROLLUP_DAILY_METRICS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    MERGE INTO TB_PIPELINE_METRICS_HISTORY tgt
    USING (
        SELECT
            Pipeline_ID,
            Execution_Start_Time::DATE                                      AS Execution_Date,
            COUNT(*)                                                        AS Total_Executions,
            SUM(IFF(Status = 'FAILED', 1, 0))                              AS Failed_Executions,
            COALESCE(SUM(Rows_Extracted), 0)                               AS Total_Rows_Extracted,
            COALESCE(SUM(Rows_Inserted),  0)                               AS Total_Rows_Inserted,
            COALESCE(SUM(Rows_Updated),   0)                               AS Total_Rows_Updated,
            AVG(DATEDIFF('second', Execution_Start_Time, Execution_End_Time)) AS Avg_Execution_Time_Seconds
        FROM DB_PROD_METADATA.SC_META_CONTROL.TB_BATCH_CONTROL
        WHERE Execution_Start_Time >= DATEADD('day', -1, CURRENT_DATE())
          AND Execution_Start_Time <  CURRENT_DATE()
        GROUP BY Pipeline_ID, Execution_Date
    ) src
    ON  tgt.Pipeline_ID     = src.Pipeline_ID
    AND tgt.Execution_Date  = src.Execution_Date
    -- Update in place if a partial run already inserted a record for this day
    WHEN MATCHED THEN UPDATE SET
        tgt.Total_Executions        = src.Total_Executions,
        tgt.Failed_Executions       = src.Failed_Executions,
        tgt.Total_Rows_Extracted    = src.Total_Rows_Extracted,
        tgt.Total_Rows_Inserted     = src.Total_Rows_Inserted,
        tgt.Total_Rows_Updated      = src.Total_Rows_Updated,
        tgt.Avg_Execution_Time_Seconds = src.Avg_Execution_Time_Seconds
    WHEN NOT MATCHED THEN INSERT (
        Pipeline_ID,         Execution_Date,         Total_Executions,
        Failed_Executions,   Total_Rows_Extracted,   Total_Rows_Inserted,
        Total_Rows_Updated,  Avg_Execution_Time_Seconds
    )
    VALUES (
        src.Pipeline_ID,         src.Execution_Date,       src.Total_Executions,
        src.Failed_Executions,   src.Total_Rows_Extracted, src.Total_Rows_Inserted,
        src.Total_Rows_Updated,  src.Avg_Execution_Time_Seconds
    );

    RETURN 'Daily Metrics Rollup Completed (idempotent MERGE)';
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. GHOST PROLIFERATION ALERT (Observability Gap — new procedure)
-- ------------------------------------------------------------------------------
-- Fires an alert if the number of unresolved Ghost (Inferred Member) records
-- in the Customer or Product dimension exceeds a configurable threshold.
-- Proliferating ghosts indicate an upstream Snowpipe failure or source API bug.
CREATE OR REPLACE PROCEDURE SP_ALERT_GHOST_PROLIFERATION()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_ghost_customer_count NUMBER;
    v_ghost_product_count  NUMBER;
    v_threshold            NUMBER DEFAULT 500; -- Alert if > 500 unresolved ghosts
BEGIN
    SELECT COUNT(*) INTO :v_ghost_customer_count
    FROM DB_PROD_CURATED.SC_SILVER_CUSTOMER.TB_CUSTOMER_DIM
    WHERE source_system = 'INFERRED_GHOST' AND is_current = TRUE;

    SELECT COUNT(*) INTO :v_ghost_product_count
    FROM DB_PROD_CURATED.SC_SILVER_PRODUCT.TB_PRODUCT_DIM
    WHERE source_system = 'INFERRED_GHOST' AND is_current = TRUE;

    -- Customer ghost proliferation alert
    IF (:v_ghost_customer_count > :v_threshold) THEN
        INSERT INTO DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE
            (Alert_Type, Severity, Pipeline_ID, Alert_Message)
        SELECT
            'GHOST_PROLIFERATION', 'HIGH', 'PIPE_SHOPIFY_CUSTOMER',
            'Ghost Customer records: ' || :v_ghost_customer_count ||
            ' active inferred members exceed threshold (' || :v_threshold ||
            '). Investigate upstream Shopify Customer Snowpipe.'
        WHERE NOT EXISTS (
            SELECT 1 FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE
            WHERE Alert_Type = 'GHOST_PROLIFERATION'
              AND Pipeline_ID = 'PIPE_SHOPIFY_CUSTOMER'
              AND Is_Resolved = FALSE
        );
    END IF;

    -- Product ghost proliferation alert
    IF (:v_ghost_product_count > :v_threshold) THEN
        INSERT INTO DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE
            (Alert_Type, Severity, Pipeline_ID, Alert_Message)
        SELECT
            'GHOST_PROLIFERATION', 'HIGH', 'PIPE_SHOPIFY_PRODUCTS',
            'Ghost Product records: ' || :v_ghost_product_count ||
            ' active inferred members exceed threshold (' || :v_threshold ||
            '). Investigate upstream Product Snowpipe.'
        WHERE NOT EXISTS (
            SELECT 1 FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE
            WHERE Alert_Type = 'GHOST_PROLIFERATION'
              AND Pipeline_ID = 'PIPE_SHOPIFY_PRODUCTS'
              AND Is_Resolved = FALSE
        );
    END IF;

    RETURN 'Ghost Proliferation Check: Customers=' || :v_ghost_customer_count
           || ', Products=' || :v_ghost_product_count;
END;
$$;
