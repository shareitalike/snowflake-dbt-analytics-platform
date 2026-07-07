{% macro get_columns_except(model, except_cols=[]) %}

{# 
    ENTERPRISE FRAMEWORK MACRO: get_columns_except
    Dynamically generates a SELECT statement including all columns from a model 
    EXCEPT for a specified list. 
    This is critical for PII obfuscation (e.g., pulling all customer data EXCEPT ssn) 
    without having to manually write out 50 column names.
    
    Usage:
    select
        {{ get_columns_except(ref('stg_customers'), ['ssn', 'credit_card_hash']) }}
    from {{ ref('stg_customers') }}
#}

    {%- if execute -%}
        {%- set model_columns = adapter.get_columns_in_relation(model) -%}
        {%- set include_cols = [] -%}
        
        {%- for col in model_columns -%}
            {%- if col.column.lower() not in except_cols | map('lower') | list -%}
                {%- do include_cols.append(col.column) -%}
            {%- endif -%}
        {%- endfor -%}
        
        {{ include_cols | join(',\n        ') }}
    {%- else -%}
        -- Return a dummy string during the parse phase
        *
    {%- endif -%}

{% endmacro %}
