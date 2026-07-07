{% macro convert_timezone(column, source_tz='UTC', target_tz='America/New_York') %}

{# 
    ENTERPRISE DATE MACRO: convert_timezone
    Abstracts timezone conversion logic. If the enterprise decides to change 
    its baseline reporting timezone, we update this one macro, and the entire 
    warehouse recompiles instantly.
    
    Usage:
    {{ convert_timezone('created_at', 'UTC', 'America/Los_Angeles') }}
#}

    {% if target.type == 'snowflake' %}
        convert_timezone('{{ source_tz }}', '{{ target_tz }}', {{ column }})
    {% else %}
        -- Standard Postgres/Redshift AT TIME ZONE fallback
        {{ column }} at time zone '{{ source_tz }}' at time zone '{{ target_tz }}'
    {% endif %}

{% endmacro %}
