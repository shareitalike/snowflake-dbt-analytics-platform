{% macro generate_audit_columns() %}

{# 
    ENTERPRISE AUDIT MACRO: generate_audit_columns
    Every model in the warehouse must adhere to strict Data Governance standards.
    Instead of typing current_timestamp() or metadata injections manually, 
    this macro enforces a standardized block of audit columns.
    
    Usage:
    select
        col1,
        col2,
        {{ generate_audit_columns() }}
    from source
#}

    -- Execution Timestamp
    current_timestamp() as dbt_updated_at,
    
    -- Execution Metadata (dbt Invocation ID)
    -- This allows data engineers to trace a specific row in the warehouse 
    -- back to the exact GitHub Actions CI/CD run that inserted it.
    '{{ invocation_id }}' as dbt_invocation_id,
    
    -- Git Commit Metadata (Requires dbt Cloud or custom env vars)
    '{{ env_var("DBT_GIT_COMMIT", "UNKNOWN_COMMIT") }}' as dbt_git_commit

{% endmacro %}
