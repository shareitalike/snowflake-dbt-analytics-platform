# Interview Notes: Documentation Framework

## Q: What are dbt Exposures and why are they critical?
**A:** "dbt natively tracks lineage from Source to Mart. But in the real world, the Mart isn't the final destination—a Power BI dashboard or a Data Science model is. Exposures extend the dbt DAG (Directed Acyclic Graph) *outside* of the data warehouse. If I define my Executive Dashboard as an Exposure, dbt will warn me if I introduce a breaking change to any upstream model that powers it. It prevents downstream blind spots."

## Q: How do you manage Business Definitions (The Data Catalog) in dbt?
**A:** "Hardcoding descriptions in `schema.yml` is an anti-pattern because the definition of 'Revenue' might be used in 20 different tables. I use dbt's `{% docs %}` blocks to build a centralized Business Glossary in Markdown. Then, I reference `{{ doc('revenue') }}` across all my YAML files. If the CFO changes the definition of Revenue, I update the Markdown file once, and the entire generated documentation site reflects the change."

## Q: How does documentation tie into Data Governance and Snowflake?
**A:** "Documentation isn't just text for humans; it's metadata for machines. I use the `meta:` block in `schema.yml` to classify data (e.g., `contains_pii: true`). Through dbt packages or custom automation, I can push that metadata directly into Snowflake Object Tagging. Snowflake then reads those tags to automatically enforce Dynamic Data Masking policies on the PII columns. The documentation *drives* the security."

## Enterprise Best Practices Demonstrated
1. **DRY Documentation:** Centralizing business logic in Markdown docs blocks.
2. **Data-as-a-Product:** Defining explicit Owners (e.g., `@marketing`) and Maturity levels (`high`, `medium`) for Exposures, treating dashboards like software products.
