{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    tags = ['domain:ecommerce', 'layer:incremental']
  )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Expected row counts: ~10k per day (Customer mutations)
    - Incremental strategy: append (High performance, audit-trail strategy)
    - Suggested cluster keys: customer_sk
    - Estimated refresh frequency: Daily
    - Downstream consumers: Marketing Analytics
*/

with customer_mutations as (
    select * from {{ ref('int_customers_enriched') }}
),

final as (
    select
        customer_sk,
        customer_id as customer_bk,
        customer_segment,
        dbt_updated_at as cdc_metadata_inserted_at
    from customer_mutations
    
    -- When configured as 'append', dbt simply runs INSERT INTO ... SELECT ...
    -- We use the CDC sliding watermark to find ONLY new/updated records.
    -- This creates a Type 2 SCD-like audit trail of customer segment changes over time.
    {{ generate_cdc_watermark(time_column='cdc_metadata_inserted_at', lookback_hours=24) }}
)

select * from final
