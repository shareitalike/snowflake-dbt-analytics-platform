/* ==============================================================================
 * FILE: fct_sales.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: A Transactional Fact table (Line Item grain) capturing the financial impact of a sale at a specific point in time.
 * DESIGN DECISIONS: Configured as an 'incremental' model (merge). Includes degenerate dimensions like 'order_id' directly in the fact table alongside metrics.
 * WHY: Degenerate dimensions (IDs that have no associated dimension table, like an Invoice Number or Order ID) are kept directly in the Fact table. This is a standard Kimball practice that allows analysts to quickly filter for specific transactions without needing to join to a massive, low-cardinality dimension table.
 * ============================================================================== */
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
