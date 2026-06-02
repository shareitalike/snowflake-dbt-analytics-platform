/* ==============================================================================
 * FILE: int_customers_enriched.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: An Intermediate model that computes heavy aggregations (e.g., Customer Lifetime Value, order counts) and joins them back to the base customer profile.
 * DESIGN DECISIONS: Materialized as a 'table'. Generating surrogate keys via dbt_utils for dimensional modeling.
 * WHY: If this model were ephemeral, the heavy GROUP BY required to calculate Lifetime Value would execute repeatedly for every downstream model that references it (like dim_customers or marketing facts). Materializing as a table caches the results, drastically optimizing warehouse compute for downstream DAG steps.
 * ============================================================================== */
{{
  config(
    materialized = 'table',
    tags = ['domain:ecommerce', 'layer:intermediate']
  )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_metrics as (
    select
        customer_id,
        min(created_at_utc) as first_order_date,
        max(created_at_utc) as most_recent_order_date,
        count(distinct order_id) as lifetime_order_count,
        sum(total_price_usd) as lifetime_value_usd
    from orders
    where order_status != 'cancelled'
    group by customer_id
),

enriched as (
    select
        {{ dbt_utils.generate_surrogate_key(['c.customer_id']) }} as customer_sk,
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email_address,
        c.is_marketing_opt_in,
        c.created_at_utc as customer_since_date,
        
        -- Business Logic: Segmentation
        coalesce(cm.lifetime_order_count, 0) as lifetime_order_count,
        coalesce(cm.lifetime_value_usd, 0) as lifetime_value_usd,
        
        case 
            when coalesce(cm.lifetime_value_usd, 0) >= 1000 then 'VIP'
            when coalesce(cm.lifetime_value_usd, 0) >= 100 then 'Active'
            else 'Occasional'
        end as customer_segment
        
    from customers c
    left join customer_metrics cm
        on c.customer_id = cm.customer_id
)

select * from enriched
