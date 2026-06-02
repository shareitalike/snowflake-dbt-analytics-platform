# Enterprise Testing Framework
## Module 09 - Design Summary

### Why Data Testing?
In traditional Data Warehousing, data quality was often an afterthought, discovered only when a VP of Finance noticed a dashboard looked incorrect. In modern Analytics Engineering, data pipelines are treated like software. We write tests to guarantee **Data Contracts**: asserting that the data meets strict quality, uniqueness, and relational standards *before* it reaches the production BI layer.

### Generic vs Singular Tests
1. **Generic Tests:** These are parameterized macros (like functions) that can be applied to any column in any table via the `schema.yml` file. 
   - *Built-in examples:* `unique`, `not_null`, `accepted_values`, `relationships`.
   - *Custom examples:* `is_positive` (a macro we build to ensure quantities or revenues never drop below zero).
2. **Singular Tests:** These are explicit SQL files written in the `tests/` directory. They are designed for highly specific, complex business logic that spans multiple tables and cannot be easily parameterized. 
   - *Rule:* If a test query returns 0 rows, it passes. If it returns 1 or more rows, it fails.
   - *Examples:* `assert_revenue_is_positive`, `assert_future_order_dates`.

### Failure Handling & CI/CD Strategy
Tests are useless if failures are ignored. We implement a strict **Severity Strategy**:
- **`warn`:** The test failed, but the pipeline continues. Used for non-critical metrics (e.g., "5% of customers don't have a zip code").
- **`error`:** The test failed, and the pipeline halts. Used for critical assertions (e.g., "Revenue is null", "Primary Key is duplicated").
In our CI/CD pipeline (e.g., GitHub Actions), a Pull Request cannot be merged if `dbt test` throws any `error` severity failures. This guarantees bad data never reaches production.
