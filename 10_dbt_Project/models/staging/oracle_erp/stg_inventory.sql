{{
  config(
    materialized = 'view',
    tags = ['domain:erp', 'layer:staging']
  )
}}

with raw_source as (
    select * from {{ source('oracle_erp', 'raw_inventory') }}
),

standardized as (
    select
        cast(sku_id as string) as product_sku,
        cast(warehouse_id as string) as warehouse_id,
        
        -- Handling nulls safely by coalescing to 0 before casting
        cast(coalesce(quantity_on_hand, 0) as integer) as quantity_on_hand,
        
        -- Standardizing boolean flags from Y/N
        case 
            when upper(is_active) = 'Y' then true
            else false 
        end as is_product_active,
        
        -- Metadata
        current_timestamp() as dbt_updated_at
        
    from raw_source
)

select * from standardized
