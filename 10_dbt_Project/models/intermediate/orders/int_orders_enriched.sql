/* ==============================================================================
 * FILE: int_orders_enriched.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: An Intermediate model that joins Order data with Customer flags and calculates derived metrics (like net_revenue_usd).
 * DESIGN DECISIONS: Materialized as 'ephemeral'. Generates surrogate keys by hashing natural keys via dbt_utils.
 * WHY: Ephemeral models do not build physical tables or views in Snowflake; they compile into CTEs injected into downstream queries. Because this model contains no heavy aggregations (just a 1:1 join), making it ephemeral prevents physical table sprawl in the warehouse while keeping the dbt codebase modular and DRY.
 * ============================================================================== */
{{
  config(
    materialized = 'ephemeral',
    tags = ['domain:ecommerce', 'layer:intermediate', 'owner:data_eng']
  )
}}

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
