/* ==============================================================================
 * FILE: access_history_queries.sql
 * PHASE: 12 - Platform Engineering
 * 
 * EXPLANATION: Provides auditing queries leveraging Snowflake's ACCESS_HISTORY to track who is querying sensitive data and monitor for potential policy violations.
 * DESIGN DECISIONS: Specifically parses the base_objects_accessed JSON array to flag whenever an object tagged with 'PII_DATA' is queried. Monitors for users repeatedly running queries that return 0 rows.
 * WHY: Monitoring 0-row queries helps detect malicious actors attempting to probe data outside their permitted row-access policies. Tracking PII access is mandatory for GDPR/CCPA compliance audits.
 * ============================================================================== */

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
