# Interview Notes: Intermediate Layer

## Q: Why not join directly in the Marts layer?
**A:** "Joining directly in the Marts layer creates monolithic SQL files that are impossible to test effectively. If `fct_sales` is a 1,000-line query doing Currency Conversion, Tax Calculation, and Customer Enrichment, a failure is impossible to isolate. By moving these transformations into modular Intermediate models (e.g., `int_currency_converted`, `int_tax_allocated`), we can unit test each individual business rule. It also prevents duplicate logic when another Mart needs that same tax calculation."

## Q: How do you avoid duplicated business logic?
**A:** "By enforcing the principle that 'A business rule should only be written once'. If we need to calculate 'Net GMV' (Gross Merchandise Value), we build an `int_orders_enriched` model that calculates it. Every downstream dashboard or Mart model *must* `ref()` that intermediate model. We never rewrite the math `(price - discount + tax)` in a downstream dashboard."

## Q: When do you choose Ephemeral vs View vs Table in the intermediate layer?
**A:** "My default is `ephemeral` because it keeps the Snowflake schema clean (no intermediate junk views cluttering the DB) and allows Snowflake to optimize the query plan end-to-end. However, if a model is computationally expensive (like a massive JSON flatten) AND it is referenced by multiple downstream facts, I will materialize it as a `table`. This acts as a caching checkpoint, preventing Snowflake from recalculating the heavy operation multiple times."

## Enterprise Best Practices Demonstrated
1. **Surrogate Key Generation:** Using `dbt_utils.generate_surrogate_key([business_key, 'static_string'])` to prepare Type 2 SCD keys before the dimensional layer.
2. **Defensive Join Testing:** Applying `unique` constraints post-join to guarantee no fan-out occurred during enrichment.
