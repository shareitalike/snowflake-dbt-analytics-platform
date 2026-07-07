{% macro generate_cdc_watermark(time_column='cdc_metadata_inserted_at', lookback_hours=72) %}

{# 
    ENTERPRISE CDC FRAMEWORK INTEGRATION:
    This macro connects dbt directly to the outputs of Phase 08 (Snowflake Streams & Tasks).
    Instead of relying on standard dbt current_date() logic, this macro pulls the maximum 
    watermark processed in the target table, and subtracts a 'lookback_hours' window to 
    safely capture any Late Arriving Data that was delayed in the upstream API.
#}

{% if is_incremental() %}
    where {{ time_column }} >= (
        select dateadd(hour, -{{ lookback_hours }}, coalesce(max({{ time_column }}), '1900-01-01'::timestamp_ntz))
        from {{ this }}
    )
{% endif %}

{% endmacro %}
