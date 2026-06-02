{% snapshot snap_store %}

{#- Strategy: check | Defensive: invalidate_hard_deletes -#}
{{
    config(
      target_schema='snapshots',
      unique_key='store_id',
      strategy='check',
      check_cols=['store_manager_id', 'region', 'is_open'],
      invalidate_hard_deletes=true,
      tags=['domain:retail', 'layer:snapshot']
    )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Snapshot Strategy: Check
    - Trade-off Justification: Retail Point-of-Sale (POS) systems often send a daily "heartbeat" 
      sync that bumps the `updated_at` timestamp on every store record, even if no physical 
      attributes changed. If we used the `timestamp` strategy, we would create a false historical 
      row every single day. The `check` strategy guarantees we only spawn an SCD2 row when a 
      meaningful attribute (like the Store Manager or Region) actually mutates.
    - Expected row counts: 1,500 base, extremely low mutation rate
*/

-- Assuming a staging model exists for stores
select 
    'STORE_001' as store_id,
    'EMP_99' as store_manager_id,
    'US-WEST' as region,
    true as is_open

{% endsnapshot %}
