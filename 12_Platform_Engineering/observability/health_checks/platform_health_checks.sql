-- ==============================================================================
-- Enterprise Platform Health Checks
-- A single SQL script that Airflow runs every 15 minutes to assess platform health.
-- Each query returns a health status. If any returns 'UNHEALTHY', alert is triggered.
-- ==============================================================================

USE ROLE ACCOUNTADMIN;

-- 1. Snowpipe Health: Are files stuck in the queue?
SELECT 
    CASE 
        WHEN COUNT(*) > 100 THEN 'UNHEALTHY: ' || COUNT(*) || ' files queued'
        ELSE 'HEALTHY'
    END AS snowpipe_health
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'OMNIRETAIL.RAW.BRONZE_LANDING',
    START_TIME => DATEADD(hour, -1, CURRENT_TIMESTAMP())
))
WHERE STATUS = 'LOAD_IN_PROGRESS';

-- 2. Stream Lag: Are CDC streams falling behind?
SELECT 
    name AS stream_name,
    stale_after,
    CASE
        WHEN stale_after < CURRENT_TIMESTAMP() THEN 'UNHEALTHY: Stream is STALE'
        ELSE 'HEALTHY'
    END AS stream_health
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())); -- Placeholder: use SHOW STREAMS in production

-- 3. Warehouse Saturation: Are queries queuing excessively?
SELECT 
    warehouse_name,
    ROUND(AVG(avg_queued_load), 2) AS avg_queued,
    CASE
        WHEN AVG(avg_queued_load) > 5 THEN 'UNHEALTHY: Excessive queuing on ' || warehouse_name
        ELSE 'HEALTHY'
    END AS warehouse_health
FROM snowflake.account_usage.warehouse_load_history
WHERE start_time >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
GROUP BY 1;

-- 4. Failed Logins: Possible brute-force or misconfigured service account?
SELECT 
    CASE 
        WHEN COUNT(*) > 20 THEN 'UNHEALTHY: ' || COUNT(*) || ' failed logins in last hour'
        ELSE 'HEALTHY'
    END AS login_health
FROM snowflake.account_usage.login_history
WHERE event_timestamp >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
  AND is_success = 'NO';

-- 5. Resource Monitor Budget: Are we approaching our monthly limit?
SELECT 
    name AS monitor_name,
    credit_quota,
    used_credits,
    ROUND(used_credits / NULLIF(credit_quota, 0) * 100, 1) AS pct_used,
    CASE
        WHEN used_credits / NULLIF(credit_quota, 0) > 0.9 THEN 'WARNING: ' || name || ' at ' || ROUND(used_credits / NULLIF(credit_quota, 0) * 100, 1) || '%'
        ELSE 'HEALTHY'
    END AS budget_health
FROM snowflake.account_usage.resource_monitors;
