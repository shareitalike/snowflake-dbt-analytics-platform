{{
  config(
    materialized = 'incremental',
    unique_key = 'order_sk',
    incremental_strategy = 'merge',
    cluster_by = ['date_sk'],
    alias = 'TB_ORDER_FACT',
    tags = ['domain:ecommerce', 'layer:marts', 'type:fact']
  )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Expected row counts: 30M+ per year (Header grain)
    - Incremental strategy: merge (Accumulating Snapshot: Orders update as status changes)
    - Suggested cluster keys: date_sk
    - Estimated refresh frequency: Every 15 minutes
    - Downstream consumers: Power BI Fulfillment SLA Dashboard, Logistics Team
*/

with orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

final as (
    select
        order_sk,
        cast(to_char(created_at_utc, 'YYYYMMDD') as integer) as date_sk,
        coalesce(customer_sk, {{ dbt_utils.generate_surrogate_key(['-1']) }}) as customer_sk,
        order_status,
        coalesce(total_price_usd, 0) as total_order_value,
        dbt_updated_at
        
    from orders_enriched
    
    {% if is_incremental() %}
        where dbt_updated_at > (select coalesce(max(dbt_updated_at), '1900-01-01') from {{ this }})
    {% endif %}
)

select * from final
