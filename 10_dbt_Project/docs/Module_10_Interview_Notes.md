# Interview Notes: Macros Framework

## Q: Why use macros instead of just writing SQL?
**A:** "Macros enforce the DRY (Don't Repeat Yourself) principle. If I have to calculate 'Net Revenue' (Price - Tax - Discount) in 15 different Mart models, and Finance decides to change the definition of Net Revenue to exclude Shipping Costs, I don't want to hunt down 15 SQL files. I want to update one Jinja macro `{{ calculate_net_revenue() }}` and have the entire warehouse inherit the new business rule."

## Q: How do macros differ from SQL models?
**A:** "A SQL model (`.sql` file in the `models/` directory) represents a physical dataset—it compiles into a `CREATE VIEW` or `CREATE TABLE` in Snowflake. A macro is just a function that returns a text string. Macros do not create tables on their own; they are injected into models to generate the final compiled SQL."

## Q: When should you create a macro?
**A:** "The 'Rule of Three'. If I write a specific piece of SQL logic once, it stays in the model. If I write it twice, I keep an eye on it. If I have to write it a third time, I immediately abstract it into a reusable macro in the `macros/` directory."

## Enterprise Best Practices Demonstrated
1. **`adapter.dispatch` awareness:** Acknowledging that enterprise macros should be database-agnostic where possible.
2. **Defensive compilation:** Using macros like `safe_cast` to prevent brittle pipelines from crashing on unexpected data types.
