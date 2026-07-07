{{
  config(
    materialized = 'incremental',
    unique_key = 'sales_sk',
    incremental_strategy = 'merge',
    cluster_by = ['date_sk'],
    alias = 'TB_SALES_FACT',
    tags = ['domain:ecommerce', 'layer:marts', 'type:fact']
  )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Expected row counts: 100M+ per year (Line item grain)
    - Incremental strategy: merge (Allows updates to late-arriving sales metrics)
    - Suggested cluster keys: date_sk (Matches >90% of BI filter conditions)
    - Estimated refresh frequency: Hourly micro-batches
    - Downstream consumers: Power BI Executive Dashboard, Daily Revenue Reports
*/

with orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'customer_id']) }} as sales_sk,
        cast(to_char(created_at_utc, 'YYYYMMDD') as integer) as date_sk,
        coalesce(customer_sk, {{ dbt_utils.generate_surrogate_key(['-1']) }}) as customer_sk,
        order_id as degenerate_order_id,
        coalesce(net_revenue_usd, 0) as net_revenue,
        coalesce(tax_price_usd, 0) as tax_amount,
        dbt_updated_at
        
    from orders_enriched
    
    {% if is_incremental() %}
        where dbt_updated_at > (select coalesce(max(dbt_updated_at), '1900-01-01') from {{ this }})
    {% endif %}
)

select * from final
