{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'insert_overwrite',
    partitions = ['date_sk'],
    cluster_by = ['date_sk'],
    tags = ['domain:supply_chain', 'layer:incremental']
  )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Expected row counts: 2B+ per year (Daily Snapshot per SKU per Store)
    - Incremental strategy: insert_overwrite (Highest performance for massive periodic snapshots)
    - Suggested cluster keys: date_sk (Matches the partition drop key)
    - Estimated refresh frequency: Daily at 01:00 AM
    - Downstream consumers: Inventory Optimization Engine
*/

with inventory as (
    -- In a real project, this would pull from a snapshot int_ model
    select * from {{ ref('stg_inventory') }} 
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['product_sku', 'warehouse_id', 'dbt_updated_at']) }} as snapshot_sk,
        cast(to_char(dbt_updated_at, 'YYYYMMDD') as integer) as date_sk,
        {{ dbt_utils.generate_surrogate_key(['product_sku']) }} as product_sk,
        {{ dbt_utils.generate_surrogate_key(['warehouse_id']) }} as store_sk,
        
        coalesce(quantity_on_hand, 0) as qoh,
        
        dbt_updated_at as cdc_metadata_inserted_at
        
    from inventory
    
    -- For insert_overwrite, we only calculate the "current" partition of data being processed.
    -- Snowflake will dynamically drop the matching partition in the target table and replace it.
    {% if is_incremental() %}
        where dbt_updated_at >= current_date()
    {% endif %}
)

select * from final
