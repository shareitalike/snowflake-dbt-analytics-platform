# Enterprise Data Validation Framework
## Module 04 - Design Summary

### Validation Strategy
Data Validation in this framework is designed as a **Fail-Fast, Multi-Tiered** gateway. Invalid data should never consume compute resources during complex transformations, nor should it ever pollute the Silver/Gold layers. We utilize Snowpark DataFrame APIs to perform distributed validation before triggering writes.

### Tier 1: Schema Validation (Pre-Flight)
Before any data is read into memory, we validate the incoming DataFrame schema against an expected target schema.
- **Constraints Checked:** Missing columns, unexpected columns, data type drift.
- **Schema Evolution:** We allow additive schema evolution (new columns in source are logged as warnings and ignored unless explicitly mapped) but strictly reject destructive evolution (missing required columns or incompatible type changes).

### Tier 2: Data Quality Framework (Row-Level)
Once the schema is validated, we run declarative Data Quality checks using Snowpark column expressions.
- **Checks:** Null thresholds, Duplicate Primary Keys, Regex Pattern matching (e.g., Email formats), and Domain constraints (e.g., `Status IN ('OPEN', 'CLOSED')`).
- **Execution:** All checks are chained into a single distributed Snowflake query using `.filter()` and aggregated, minimizing warehouse round-trips.

### Tier 3: Business Validation Framework
Domain-specific logic that requires cross-column or cross-table evaluation.
- **Example:** An `Order` must have a valid `Customer_ID` that exists in the Dimension table (Referential Integrity), and the `Order_Total` must equal the sum of its `Order_Items`.

### Quarantine Framework (Dead Letter Queue)
Rows that fail Tier 2 or Tier 3 checks are not simply dropped. 
- Using Snowpark's DataFrame splitting (e.g., `df.filter(valid_condition)` vs `df.filter(~valid_condition)`), failed rows are routed to a **Quarantine Table** (e.g., `DB_PROD_RAW.SC_QUARANTINE.TB_ORDERS_DLQ`).
- A `Rejection_Reason` and `Pipeline_Run_ID` column are appended to the quarantined rows for Data Stewards to review, fix, and replay using the Phase 08 Replay Framework.
