{{
  config(
    materialized = 'ephemeral',
    tags = ['domain:finance', 'layer:intermediate']
  )
}}

with payments as (
    select * from {{ ref('stg_payments') }}
),

payment_methods as (
    select * from {{ ref('payment_methods') }} -- This is a SEED
),

reconciled as (
    select
        {{ dbt_utils.generate_surrogate_key(['p.payment_id']) }} as payment_sk,
        {{ dbt_utils.generate_surrogate_key(['p.order_id']) }} as order_sk,
        
        p.payment_id,
        p.order_id,
        p.payment_amount,
        p.currency_code,
        p.payment_status,
        
        -- Seed Reference Data Lookup
        coalesce(pm.payment_method_name, 'UNMAPPED_METHOD') as payment_method_name,
        coalesce(pm.fee_percentage, 0) as gateway_fee_percentage,
        
        -- Business Rule: Calculate Gateway Fee
        (p.payment_amount * coalesce(pm.fee_percentage, 0)) as calculated_gateway_fee_amount,
        
        p.created_at_utc
        
    from payments p
    left join payment_methods pm
        on p.payment_status = pm.payment_method_code -- Assuming status maps to code for demo
)

select * from reconciled
