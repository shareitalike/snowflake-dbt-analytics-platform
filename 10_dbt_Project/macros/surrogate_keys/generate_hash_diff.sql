{% macro generate_hash_diff(columns=[]) %}

{# 
    ENTERPRISE FRAMEWORK MACRO: generate_hash_diff
    Generates a deterministic MD5 hash of multiple columns. 
    This is an advanced SCD Type 2 detection pattern. Instead of comparing 50 columns 
    row-by-row to see if a record mutated, we simply compare the `hash_diff` of the new 
    row against the `hash_diff` of the current row. If the hashes don't match, a mutation occurred.
    
    Usage:
    {{ generate_hash_diff(['first_name', 'last_name', 'address', 'segment']) }} as customer_hash_diff
#}

    {%- if columns | length > 0 -%}
        md5(
            {%- for col in columns -%}
                coalesce(cast({{ col }} as varchar), '~~DBT_NULL_VALUE~~')
                {%- if not loop.last %} || '|' || {% endif -%}
            {%- endfor -%}
        )
    {%- else -%}
        null
    {%- endif -%}

{% endmacro %}
