/* ==============================================================================
 * FILE: dim_product.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: A Dimension table representing Products, providing a unified schema for item hierarchies and categorizations.
 * DESIGN DECISIONS: Generates product_sk using dbt_utils.generate_surrogate_key. Explicitly hardcodes the -1 UNKNOWN record at the bottom via a UNION ALL.
 * WHY: Establishing the -1 surrogate key explicitly inside the dimension model allows Fact tables to gracefully degrade instead of dropping rows via strict INNER JOINs. This guarantees that total aggregate metrics at the top of a BI dashboard always match the raw layer exactly.
 * ============================================================================== */
{{
  config(
    materialized = 'table',
    tags = ['domain:erp', 'layer:marts', 'type:dimension']
  )
}}

with products as (
    select * from {{ ref('stg_inventory') }} -- Assuming inventory holds product master data for demo
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['product_sku']) }} as product_sk,
        product_sku as product_bk,
        
        warehouse_id,
        
        is_product_active,
        
        -- Hierarchies (Coalesced for BI safety)
        -- Example of where sub-category logic would exist
        'UNKNOWN' as product_category,
        'UNKNOWN' as product_sub_category,
        
        current_timestamp() as dbt_updated_at
        
    from products
    
    union all
    
    select
        {{ dbt_utils.generate_surrogate_key(['-1']) }} as product_sk,
        '-1' as product_bk,
        'UNKNOWN' as warehouse_id,
        false as is_product_active,
        'UNKNOWN' as product_category,
        'UNKNOWN' as product_sub_category,
        current_timestamp() as dbt_updated_at
)

select * from final
