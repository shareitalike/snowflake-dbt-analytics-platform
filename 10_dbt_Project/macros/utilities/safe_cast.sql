{% macro safe_cast(field, type) %}

{# 
    ENTERPRISE UTILITY MACRO: safe_cast
    Instead of using standard SQL `cast(col as int)`, which crashes the pipeline 
    if a rogue string like 'N/A' appears, this macro wraps the cast in a defensive 
    statement. In Snowflake, this natively translates to `try_cast()`, which safely 
    converts unparseable strings to NULL without halting execution.
    
    Usage:
    {{ safe_cast('quantity_ordered', 'integer') }}
#}

    {% if target.type == 'snowflake' %}
        try_cast({{ field }} as {{ type }})
    {% else %}
        -- Fallback for generic ANSI SQL (e.g., Postgres doesn't have try_cast natively)
        cast({{ field }} as {{ type }})
    {% endif %}

{% endmacro %}
