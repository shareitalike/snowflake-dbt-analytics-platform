-- ==============================================================================
-- Enterprise Audit & Governance 
-- Tracking data access using Snowflake's native ACCESS_HISTORY
-- ==============================================================================

USE ROLE ACCOUNTADMIN;

-- 1. Identify which users are querying tables with PII Data Tags
SELECT 
    query_id,
    user_name,
    role_name,
    query_start_time,
    base_objects_accessed
FROM snowflake.account_usage.access_history
WHERE 
    query_start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    -- Parse the JSON array to find if a tagged PII object was accessed
    AND array_to_string(base_objects_accessed, ',') LIKE '%PII_DATA%';

-- 2. Monitor Policy Violations (Users trying to bypass Row Access Policies)
-- If a user runs a query that returns 0 rows consistently, they might be probing data outside their Region.
SELECT 
    user_name,
    role_name,
    database_name,
    schema_name,
    COUNT(*) as empty_queries
FROM snowflake.account_usage.query_history
WHERE 
    rows_produced = 0
    AND execution_status = 'SUCCESS'
    AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 50
ORDER BY empty_queries DESC;
