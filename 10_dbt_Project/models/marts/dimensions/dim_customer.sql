/* ==============================================================================
 * FILE: dim_customer.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: A Kimball-style Dimension table representing the current state of a Customer. Merges enriched intermediate metrics (Lifetime Value) with core profile attributes.
 * DESIGN DECISIONS: Materialized as a 'table'. Includes a default -1 / UNKNOWN record unioned at the bottom.
 * WHY: The -1 record is a critical Data Warehousing pattern to handle "Late Arriving Dimensions" or orphaned facts (e.g., an Order arrives before the Customer profile syncs). Downstream Fact tables use coalesce(customer_sk, '-1') to ensure Referential Integrity without dropping the orphaned revenue from top-level BI reporting.
 * ============================================================================== */
{{
  config(
    materialized = 'table',
    tags = ['domain:ecommerce', 'layer:marts', 'type:dimension']
  )
}}

with enriched_customers as (
    select * from {{ ref('int_customers_enriched') }}
),

final as (
    select
        -- Surrogate Key
        customer_sk,
        
        -- Business Key
        customer_id as customer_bk,
        
        -- Attributes
        coalesce(first_name, 'UNKNOWN') as first_name,
        coalesce(last_name, 'UNKNOWN') as last_name,
        coalesce(email_address, 'UNKNOWN') as email_address,
        
        -- Flags
        coalesce(is_marketing_opt_in, false) as is_marketing_opt_in,
        
        -- Hierarchy / Segmentation
        coalesce(customer_segment, 'UNKNOWN') as customer_segment,
        
        -- Metrics (Often kept in facts, but useful as dimensional attributes for slicing)
        lifetime_order_count,
        lifetime_value_usd,
        customer_since_date,
        
        -- SCD Type 1 logic (Current state)
        -- SCD2 tracking (valid_from/valid_to) is handled via dbt snapshots in the raw layer,
        -- but for this Mart table, we expose the current snapshot.
        
        -- Audit
        current_timestamp() as dbt_updated_at
        
    from enriched_customers
    
    union all
    
    -- Explicit UNKNOWN record to handle Late Arriving Dimensions (Orphaned Facts)
    select
        {{ dbt_utils.generate_surrogate_key(['-1']) }} as customer_sk,
        '-1' as customer_bk,
        'UNKNOWN' as first_name,
        'UNKNOWN' as last_name,
        'UNKNOWN' as email_address,
        false as is_marketing_opt_in,
        'UNKNOWN' as customer_segment,
        0 as lifetime_order_count,
        0 as lifetime_value_usd,
        '1900-01-01'::timestamp_ntz as customer_since_date,
        current_timestamp() as dbt_updated_at
)

select * from final
