{% snapshot snap_supplier %}

{{
    config(
      target_schema='snapshots',
      unique_key='supplier_id',
      
      -- Strategy configuration
      strategy='check',
      check_cols=['contract_status', 'payment_terms', 'contact_email'],
      
      -- Defensive configurations
      invalidate_hard_deletes=True,
      
      tags=['domain:supply_chain', 'layer:snapshot']
    )
}}

/*
    MODEL PERFORMANCE NOTES:
    - Snapshot Strategy: Check
    - Trade-off Justification: Third-party vendor portals often provide flat CSV drops via SFTP 
      without any reliable metadata or audit timestamps. Because we lack a trustworthy `updated_at` 
      column, the `check` strategy is absolutely mandatory to detect SCD2 mutations.
    - Expected row counts: 3,000 base, very low mutation rate
*/

select 
    'SUPP_001' as supplier_id,
    'Active' as contract_status,
    'Net-30' as payment_terms,
    'vendor@example.com' as contact_email

{% endsnapshot %}
