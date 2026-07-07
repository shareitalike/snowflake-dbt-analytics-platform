{{
  config(
    materialized = 'ephemeral',
    tags = ['domain:ecommerce', 'layer:intermediate', 'owner:data_eng']
  )
}}

/*
    Trade-off Justification:
    Materialized as 'ephemeral' to prevent physical table sprawl. This logic will be injected 
    directly into fct_orders via CTEs, allowing Snowflake to optimize the final query plan.
*/

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

enriched as (
    select
        -- Surrogate Key Generation for dimensional modeling
        {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as order_sk,
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_sk,
        
        o.order_id,
        o.customer_id,
        o.order_status,
        
        -- Customer Enrichment (pulling boolean flag for marketing)
        c.is_marketing_opt_in as is_customer_marketable,
        
        -- Derived Business Logic (Net Revenue Calculation)
        o.total_price_usd,
        o.tax_price_usd,
        (o.total_price_usd - coalesce(o.tax_price_usd, 0)) as net_revenue_usd,
        
        o.created_at_utc,
        o.updated_at_utc,
        
        -- Audit
        current_timestamp() as dbt_updated_at
        
    from orders o
    left join customers c
        on o.customer_id = c.customer_id
)

select * from enriched
