{{
  config(
    materialized = 'view',
    tags = ['domain:ecommerce', 'layer:staging', 'owner:data_eng']
  )
}}

/*
    Trade-off Justification:
    Materialized as 'view' because staging models perform no heavy aggregations.
    A view pushes the compute down to downstream models, avoiding redundant storage costs.
*/

with raw_source as (
    select * from {{ source('shopify', 'raw_orders') }}
),

deduplicated as (
    -- Handling duplicates using dbt_utils macro to ensure clean data enters Gold
    {{ dbt_utils.deduplicate(
        relation='raw_source',
        partition_by='order_id',
        order_by='metadata_inserted_at desc'
    ) }}
),

standardized as (
    select
        -- Primary Key
        cast(order_id as string) as order_id,

        -- Foreign Keys
        cast(customer_id as string) as customer_id,
        cast(nullif(store_id, '') as string) as store_id, -- Null handling

        -- Dimensions
        cast(status as string) as order_status,
        
        -- Explicit timezone casting and naming convention enforcement
        convert_timezone('UTC', cast(created_at as timestamp_ntz)) as created_at_utc,
        convert_timezone('UTC', cast(updated_at as timestamp_ntz)) as updated_at_utc,
        
        -- Measures
        cast(total_price as numeric(10,2)) as total_price_usd,
        cast(tax_price as numeric(10,2)) as tax_price_usd,

        -- Audit Metadata (Preserving CDC timestamp and adding dbt timestamp)
        cast(metadata_inserted_at as timestamp_ntz) as source_inserted_at,
        current_timestamp() as dbt_updated_at

    from deduplicated
)

select * from standardized
