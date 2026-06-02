/* ==============================================================================
 * FILE: fct_orders.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: An Accumulating Snapshot Fact table tracking the lifecycle and state of an Order (e.g., pending -> shipped -> delivered).
 * DESIGN DECISIONS: Configured as an 'incremental' model using the 'merge' strategy and clustered by 'date_sk'. Filters on dbt_updated_at to only process new or changed records.
 * WHY: A fact table that tracks state changes (like order status updates) must use the 'merge' strategy rather than 'append' to avoid duplicating records. Clustering by date_sk aligns physically with how BI tools query the data (Time Series), ensuring Snowflake prunes micro-partitions effectively and keeps dashboard latency under 1 second.
 * ============================================================================== */
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
