{% snapshot snap_employee %}

{#- Strategy: timestamp | Defensive: invalidate_hard_deletes -#}
{{
    config(
      target_schema='snapshots',
      unique_key='employee_id',
      strategy='timestamp',
      updated_at='last_modified_date',
      invalidate_hard_deletes=true,
      tags=['domain:hr', 'layer:snapshot']
    )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Snapshot Strategy: Timestamp
    - Trade-off Justification: Enterprise HR systems (like Workday) maintain extremely rigorous 
      audit trails and provide a highly reliable `last_modified_date`. Because the timestamp is 
      trustworthy and only fires on genuine mutations, the `timestamp` strategy is preferred for 
      its superior performance (preventing dbt from having to do row-by-row hash comparisons).
    - Expected row counts: 15,000 base, moderate mutation rate (promotions, transfers)
*/

select 
    'EMP_001' as employee_id,
    'Sales Associate' as job_title,
    'STORE_001' as assigned_store_id,
    current_timestamp() as last_modified_date

{% endsnapshot %}
