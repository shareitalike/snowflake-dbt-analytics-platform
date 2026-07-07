# Enterprise Documentation & Data Catalog Framework
## Module 11 - Design Summary

### Why Documentation & Data Catalogs?
An enterprise Data Warehouse is completely useless if the business cannot trust or understand the data. If a Marketing Analyst pulls `net_revenue` from `fct_sales` and it doesn't match the `net_revenue` in the Finance Dashboard, trust is broken. A robust Data Catalog acts as the single source of truth for Business Definitions, Technical Definitions, and Ownership.

### Data Lineage & Exposures
dbt tracks internal lineage (Staging -> Intermediate -> Marts) natively via the `{{ ref() }}` function. However, dbt loses visibility once the data leaves Snowflake. 
**Exposures** solve this by formally defining downstream consumers (e.g., Power BI Dashboards, Machine Learning models) inside the dbt codebase. 
If an Analytics Engineer attempts to deprecate a column in `dim_customer`, dbt will warn them: *"Wait! The Executive Power BI Dashboard depends on this column!"*

### The Business Glossary (`docs` blocks)
Writing the definition of "Gross Merchandise Value (GMV)" inside the `schema.yml` of 15 different models is an anti-pattern. If Finance updates the definition, you must find and replace it 15 times.
By utilizing dbt `docs` blocks (`{%- raw -%}{%- endraw -%}` pattern), we write the Business Definition *once* in a centralized markdown file (`business_glossary.md`). The `schema.yml` files simply reference it via `doc('gmv')`. This is the cornerstone of enterprise Data Governance.
