{{
  config(
    materialized = 'table',
    tags = ['domain:reference', 'layer:marts', 'type:dimension']
  )
}}

/*
    Trade-off Justification:
    Materialized as 'table'. The Date dimension is static and small (a few thousand rows).
    It is the most heavily joined table in the warehouse. Generating it on the fly is cheap.
*/

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2018-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    )
    }}
),

final as (
    select
        -- Surrogate Key (YYYYMMDD integer format for efficient joins)
        cast(to_char(date_day, 'YYYYMMDD') as integer) as date_sk,
        
        -- Business Key
        cast(date_day as date) as date_bk,
        
        -- Attributes
        extract(year from date_day) as year_num,
        extract(quarter from date_day) as quarter_num,
        extract(month from date_day) as month_num,
        extract(day from date_day) as day_of_month_num,
        extract(dayofweek from date_day) as day_of_week_num,
        
        to_char(date_day, 'MMMM') as month_name,
        to_char(date_day, 'DY') as day_of_week_name,
        
        case when extract(dayofweek from date_day) in (0, 6) then true else false end as is_weekend,
        
        -- Audit
        current_timestamp() as dbt_updated_at
        
    from date_spine
)

select * from final
