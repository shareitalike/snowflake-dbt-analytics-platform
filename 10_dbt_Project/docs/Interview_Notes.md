# Interview Notes: dbt Cloud Architecture

## Q: Why dbt? Why not Stored Procedures?
**A:** "Stored procedures are monolithic black boxes. They are difficult to version control, nearly impossible to unit test effectively, and trap business logic in proprietary SQL syntax. dbt brings Software Engineering principles to SQL. It allows us to write modular, DRY code using Jinja, automatically handles dependency mapping via a DAG, and enforces rigorous testing and documentation directly alongside the code."

## Q: Why ELT instead of ETL?
**A:** "In traditional ETL, data is transformed in a middle-tier server (like Informatica) before being loaded into the warehouse. This is a massive bottleneck. Snowflake has virtually infinite compute scaling. ELT extracts raw data, loads it into Snowflake's Bronze layer instantly via Snowpipe, and then dbt leverages Snowflake's own native compute engines to transform the data *in-place*. It's faster, cheaper, and removes the middleman."

## Q: How do you organize a large enterprise dbt project?
**A:** "Strict adherence to the Medallion / dbt Labs layer architecture. 
1. **Sources:** Explicit declarations of raw tables.
2. **Staging:** 1:1 mapping with sources to clean names, cast types, and establish a common schema. No joins allowed.
3. **Intermediate:** Where the complex business logic and entity joining happens. 
4. **Marts:** Final Kimball Star Schema (Dimensions and Facts) strictly modeled for BI consumption. 
This prevents the 'spaghetti SQL' problem where raw tables are joined directly to BI layers."

## Enterprise Best Practices Demonstrated
1. **Slim CI (`state:modified+1`):** Shows advanced understanding of FinOps by not rebuilding the entire warehouse on every Pull Request.
2. **Environment Isolation (Profiles):** Strictly separating `DB_DEV_GOLD` from `DB_PROD_GOLD` using target variables.
3. **Incremental Strategies:** Utilizing `MERGE` statements on Fact tables to process only deltas, saving massive Snowflake credits.
