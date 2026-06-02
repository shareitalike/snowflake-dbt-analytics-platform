{% test is_positive(model, column_name) %}

{# 
    ENTERPRISE GENERIC TEST:
    This macro ensures that numerical columns (like quantities or revenue) 
    never drop below zero. 
    Usage in schema.yml:
      - name: net_revenue
        tests:
          - is_positive
#}

with validation as (
    select
        {{ column_name }} as numeric_field
    from {{ model }}
),

validation_errors as (
    select
        numeric_field
    from validation
    where numeric_field < 0
)

select *
from validation_errors

{% endtest %}
