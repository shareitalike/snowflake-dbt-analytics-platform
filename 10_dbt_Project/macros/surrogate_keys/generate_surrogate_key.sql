{% macro generate_surrogate_key(columns=[]) %}

{# 
    ENTERPRISE FRAMEWORK MACRO: generate_surrogate_key
    While dbt_utils provides a surrogate_key macro, enterprise frameworks often wrap it.
    This guarantees that if the enterprise ever migrates off dbt_utils, or decides to change 
    their hashing algorithm from MD5 to SHA256 for compliance reasons, they only have to 
    update this single wrapper macro instead of 500 models.
    
    Usage:
    {{ generate_surrogate_key(['order_id', 'line_item_id']) }} as sales_sk
#}

    -- Enterprise Default: Utilize dbt_utils MD5 hashing
    {{ dbt_utils.generate_surrogate_key(columns) }}

{% endmacro %}
