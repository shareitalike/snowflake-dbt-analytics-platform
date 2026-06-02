-- ENTERPRISE SINGULAR TEST: Revenue Reconciliation
-- This test ensures that the total GMV in the Gold layer (fct_sales) 
-- exactly matches the raw total GMV in the Silver layer (stg_orders).
-- If the join logic in the intermediate layer caused a fan-out or dropped records, 
-- this test will fail, preventing bad financial data from reaching Executive Dashboards.

-- Rule: A passing test returns 0 rows.

with staging_totals as (
    select 
        date_trunc('day', created_at_utc) as sales_date,
        sum(total_price_usd) as stg_total_gmv
    from {{ ref('stg_orders') }}
    group by 1
),

fact_totals as (
    select 
        cast(to_char(date_sk, 'YYYY-MM-DD') as date) as sales_date,
        -- fact_sales calculates Net Revenue, so we add tax back to reconcile against raw GMV
        sum(net_revenue + tax_amount) as fct_total_gmv
    from {{ ref('fct_sales') }}
    group by 1
),

reconciliation_errors as (
    select 
        s.sales_date,
        s.stg_total_gmv,
        f.fct_total_gmv,
        abs(s.stg_total_gmv - f.fct_total_gmv) as variance_amount
    from staging_totals s
    join fact_totals f on s.sales_date = f.sales_date
    -- We allow a $0.01 variance to account for minor floating point rounding during sum aggregation
    where abs(s.stg_total_gmv - coalesce(f.fct_total_gmv, 0)) > 0.01
)

select * from reconciliation_errors
