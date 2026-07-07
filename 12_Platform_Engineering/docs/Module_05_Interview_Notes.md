# Interview Notes: Snowflake Security & Governance

## Q: How do Dynamic Data Masking and Row Access Policies work together?
**A:** "They form a complete matrix of data protection. A **Row Access Policy** restricts *which rows* a user can see (e.g., Regional Managers only see their region's sales). A **Dynamic Data Masking** policy restricts *what columns* a user can see within those rows (e.g., masking the customer email). In Snowflake, these policies are evaluated at query runtime based on the `current_role()`. The underlying data on disk is never altered, meaning we don't have to duplicate tables for different user groups."

## Q: How do you implement Role-Based Access Control (RBAC)?
**A:** "I strictly follow the principle of Least Privilege. We separate System Roles (Sysadmin) from Functional Roles (Data Engineer, Analyst) and Service Roles (Airflow, dbt). I never assign privileges directly to a user. Instead, I grant usage on the database to a functional role, and then grant that functional role to the user. I also ensure all functional roles roll up to `SYSADMIN` so the engineering team maintains full architectural visibility."

## Q: How do you audit data access for Compliance (GDPR/SOX)?
**A:** "Snowflake makes this incredibly easy via the `SNOWFLAKE.ACCOUNT_USAGE` schema. First, I use **Object Tags** to classify sensitive columns as `PII_DATA`. Then, I query the `ACCESS_HISTORY` view to see exactly which users and roles queried the tagged columns, down to the exact millisecond and `query_id`. For tracking authorization changes, I query `GRANTS_TO_USERS`."

## Q: How do you handle Data Retention and Disaster Recovery?
**A:** "I configure **Time Travel** based on the layer. Raw (Bronze) gets 90 days of Time Travel so we can undrop tables if a pipeline corrupts data. Gold gets 1 day because dbt can instantly rebuild it. Beyond Time Travel, Snowflake's 7-day **Fail-safe** ensures that even if a table is dropped and Time Travel expires, Snowflake support can recover it."
