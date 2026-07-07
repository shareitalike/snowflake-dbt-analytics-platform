{{
  config(
    materialized = 'view',
    tags = ['domain:finance', 'layer:staging']
  )
}}

with raw_source as (
    select * from {{ source('stripe', 'raw_charges') }}
),

standardized as (
    select
        cast(charge_id as string) as payment_id,
        cast(order_id as string) as order_id,
        
        -- Casting currency types
        cast(amount as numeric(12,2)) as payment_amount,
        upper(cast(currency as string)) as currency_code,
        
        -- Standardizing status outputs
        lower(cast(status as string)) as payment_status,
        
        convert_timezone('UTC', cast(created_at as timestamp_ntz)) as created_at_utc,
        
        current_timestamp() as dbt_updated_at
        
    from raw_source
)

select * from standardized
