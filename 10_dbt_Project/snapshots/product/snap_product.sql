{% snapshot snap_product %}

{#- Strategy: check | Defensive: invalidate_hard_deletes -#}
{{
    config(
      target_schema='snapshots',
      unique_key='product_sku',
      strategy='check',
      check_cols=['is_product_active', 'warehouse_id'],
      invalidate_hard_deletes=true,
      tags=['domain:supply_chain', 'layer:snapshot']
    )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Snapshot Strategy: Check (Explicit column tracking)
    - Trade-off Justification: The ERP system updates `dbt_updated_at` every night during 
      a batch recalculation, even if the product attributes didn't change. If we used the 
      'timestamp' strategy, we would create a duplicate historical row every single day, 
      causing massive snapshot bloat. By using `check_cols`, dbt will ONLY create a new 
      historical record if the 'is_product_active' flag or 'warehouse_id' actually mutate.
    - Expected row counts: 50k items, slow mutation rate
*/

select 
    * 
from {{ ref('stg_inventory') }}

{% endsnapshot %}
