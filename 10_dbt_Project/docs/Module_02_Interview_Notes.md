# Interview Notes: Sources & Seeds

## Q: Why use dbt sources instead of querying raw tables directly?
**A:** "Hardcoding raw database paths like `FROM DB_PROD_RAW.SCHEMA.TABLE` creates massive tech debt. It prevents environment isolation—you can't easily switch between DEV and PROD data. By using the `{{ source('schema', 'table') }}` macro, dbt dynamically targets the correct environment database. Furthermore, declaring sources unlocks Source Freshness monitoring and Data Contracts, allowing us to validate raw data *before* spending compute credits to transform it."

## Q: When should reference data be stored as seeds?
**A:** "Seeds are strictly for slowly changing, low-volume reference data—like Country ISO Codes, Currency Mappings, or fixed Tax Brackets. I never use seeds for large dimensional data like Customers or Products. The massive benefit of seeds is that they place reference data under Git Version Control. To update a lookup table, a business analyst simply submits a Pull Request on a CSV file, creating an immutable audit trail of exactly *who* changed a tax rate and *when*."

## Q: How do you monitor source freshness?
**A:** "Our Data Engineering pipelines (built in Phase 8) append a `METADATA_INSERTED_AT` timestamp to every row they write to the raw layer. In dbt, I configure the `loaded_at_field` to point to this timestamp. I then set an `error_after: {count: 4, period: hour}` threshold on tier-1 sources like Shopify Orders. Before the main dbt DAG runs, I execute `dbt source freshness`. If the raw data is older than 4 hours, the dbt run aborts, and an alert is routed to PagerDuty."

## Enterprise Best Practices Demonstrated
1. **Defensive Modeling:** Validating `unique` and `not_null` on the raw primary keys prevents cartesian explosions downstream.
2. **Configuration as Code (CaC):** Moving reference data from hidden DBA-managed scripts into version-controlled CSVs (Seeds).
