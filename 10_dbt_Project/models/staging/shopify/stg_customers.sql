/* ==============================================================================
 * FILE: stg_customers.sql
 * PHASE: 10 - dbt Project
 * 
 * EXPLANATION: A Bronze-to-Silver Staging model. Responsible for casting raw strings to specific data types, standardizing boolean values, and standardizing column names for downstream use.
 * DESIGN DECISIONS: Uses materialized='view' to push compute down to the Intermediate models, saving storage costs. Enforces UTC timezone conversions explicitly.
 * WHY: Staging models act as a rigid contract between the raw data and the business logic. If an upstream source changes a column name (e.g., accepts_marketing -> marketing_opt_in), we only have to fix it here in the staging model, shielding the rest of the DAG from failure.
 * ============================================================================== */
{{
  config(
    materialized = 'view',
    tags = ['domain:ecommerce', 'layer:staging']
  )
}}

with raw_source as (
    select * from {{ source('shopify', 'raw_customers') }}
),

standardized as (
    select
        cast(customer_id as string) as customer_id,
        
        -- PII Handling (Masking is handled via Snowflake policies, but we standardize names here)
        cast(first_name as string) as first_name,
        cast(last_name as string) as last_name,
        cast(email as string) as email_address,
        
        -- Boolean standardization (casting "1"/"0" or "Y"/"N" to native boolean if needed)
        cast(accepts_marketing as boolean) as is_marketing_opt_in,
        
        convert_timezone('UTC', cast(created_at as timestamp_ntz)) as created_at_utc,
        
        current_timestamp() as dbt_updated_at
        
    from raw_source
)

select * from standardized
