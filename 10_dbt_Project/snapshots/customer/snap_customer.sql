{% snapshot snap_customer %}

{#- Strategy: timestamp | Defensive: invalidate_hard_deletes -#}
{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='dbt_updated_at',
      invalidate_hard_deletes=true,
      tags=['domain:ecommerce', 'layer:snapshot']
    )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Snapshot Strategy: Timestamp (High performance, relies on upstream metadata)
    - Hard Deletes: Enabled. If a customer is deleted in Shopify (violating privacy compliance 
      if we keep it active), dbt will automatically expire the record by setting dbt_valid_to.
    - Expected row counts: 5M initially, +10k daily mutations
    - Downstream consumers: int_customers_enriched (which generates Surrogate Keys based on dbt_valid_from)
*/

select 
    -- We snapshot directly from the staging layer to capture the pristine 1:1 state
    * 
from {{ ref('stg_customers') }}

{% endsnapshot %}
