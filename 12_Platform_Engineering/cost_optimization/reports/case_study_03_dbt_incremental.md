# CASE STUDY 3: dbt Model — Full Refresh to Incremental Conversion
## Scenario
The `fct_sales` model was materialized as `table` (full refresh). Every dbt run dropped and rebuilt the entire 500M-row fact table from scratch, consuming 45 minutes and ~12 credits on `PROD_DBT_WH (LARGE)`.

## Before (Full Refresh)
```sql
-- models/marts/facts/fct_sales.sql (BEFORE)
{{ config(materialized='table') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['order_id', 'line_item_id']) }} AS sale_key,
    order_id,
    customer_id,
    product_id,
    store_id,
    sale_date,
    quantity,
    unit_price,
    discount_amount,
    quantity * unit_price - discount_amount AS net_sale_amount,
    CURRENT_TIMESTAMP() AS _etl_loaded_at
FROM {{ ref('stg_orders') }}
```
**Runtime:** 45 minutes | **Credits:** 12.1 | **Rows Processed:** 500,000,000

## After (Incremental with Merge)
```sql
-- models/marts/facts/fct_sales.sql (AFTER)
{{ config(
    materialized='incremental',
    unique_key='sale_key',
    incremental_strategy='merge',
    cluster_by=['sale_date'],
    on_schema_change='sync_all_columns'
) }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['order_id', 'line_item_id']) }} AS sale_key,
    order_id,
    customer_id,
    product_id,
    store_id,
    sale_date,
    quantity,
    unit_price,
    discount_amount,
    quantity * unit_price - discount_amount AS net_sale_amount,
    CURRENT_TIMESTAMP() AS _etl_loaded_at
FROM {{ ref('stg_orders') }}
{% if is_incremental() %}
WHERE _etl_loaded_at > (SELECT MAX(_etl_loaded_at) FROM {{ this }})
{% endif %}
```

## Results

| Metric | Full Refresh | Incremental | Improvement |
|--------|-------------|-------------|-------------|
| Runtime | 45 min | 3 min 20s | **13x faster** |
| Credits | 12.1 | 0.8 | **93% reduction** |
| Rows Processed | 500M | ~35K (delta) | **99.99% fewer** |
| Monthly Cost (daily run) | $1,089 | $72 | **$1,017/month saved** |

*"Never use `materialized='table'` on a large fact table that receives daily appends. Convert it to `incremental` with a `merge` strategy. The `is_incremental()` Jinja macro adds a WHERE clause that only processes the delta, reducing both compute and time by over 90%."*
