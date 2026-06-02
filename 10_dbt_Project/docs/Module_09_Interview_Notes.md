# Interview Notes: Testing Framework

## Q: How do you prevent bad data from reaching production?
**A:** "We treat data like software. In our dbt pipeline, every model has an accompanying `schema.yml` that defines the Data Contract (`unique`, `not_null`, `accepted_values`). During our CI/CD process (like a GitHub Action), we run `dbt build` on a clone of the schema. If any test throws an `error` severity, the deployment is blocked. Bad data physically cannot merge into the production branch."

## Q: What is the difference between generic and singular tests?
**A:** "Generic tests are reusable macros. If I write a `test_is_positive` macro, I can apply it to `net_revenue` in `fct_sales` and `quantity_on_hand` in `fct_inventory` just by adding two lines to my `schema.yml`. Singular tests are one-off SQL queries stored in the `tests/` directory. I use them for highly complex, multi-table business logic—like asserting that the total revenue in the Marts layer exactly matches the total revenue in the Staging layer to prove no data was dropped during the ETL process."

## Q: How do you handle non-critical data quality issues?
**A:** "Not all data issues should break the pipeline. For example, if a customer's 'Phone Number' is null, we want to know about it, but we don't want to stop the hourly Sales dashboard from refreshing. We handle this by setting the `severity: warn` configuration in dbt. This logs the failure to our Data Quality Dashboard without failing the overarching DAG run."

## Enterprise Best Practices Demonstrated
1. **Zero-Row Paradigms:** Writing singular tests using the paradigm that "a passing test returns zero rows."
2. **Custom Generic Macros:** Building `is_positive` to abstract business rules away from boilerplate SQL.
