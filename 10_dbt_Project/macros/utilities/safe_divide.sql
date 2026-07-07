{% macro safe_divide(numerator, denominator) %}

{# 
    ENTERPRISE FRAMEWORK MACRO: safe_divide
    Prevents "Division by Zero" errors that crash data pipelines. 
    If the denominator is 0 or NULL, this gracefully returns NULL (or optionally 0).
    Highly reusable across any project calculating margins, conversion rates, or percentages.
    
    Usage:
    {{ safe_divide('gross_profit', 'net_revenue') }} as gross_margin_pct
#}

    case 
        when {{ denominator }} is null then null
        when {{ denominator }} = 0 then null
        else ({{ numerator }} * 1.0) / {{ denominator }}
    end

{% endmacro %}
