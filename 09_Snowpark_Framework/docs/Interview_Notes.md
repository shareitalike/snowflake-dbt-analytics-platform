# Enterprise Snowpark Framework - Interview Notes

**Phase 09 – Module 1**  
**Role:** Principal Snowflake Architect & Python Engineer  

This document prepares you for technical defense questions regarding the adoption and architecture of Snowpark in a Fortune 500 enterprise environment.

---

## 1. Why Snowpark?

**Question:** Why did you choose Snowpark over continuing to use standard SQL Stored Procedures or dbt?

**Defense:**
- **Skillset:** It allows us to leverage Python, which is the lingua franca of Data Engineering and Data Science, directly within Snowflake.
- **Compute Locality:** Unlike external Python execution (e.g., AWS Glue, MWAA Operators pulling data), Snowpark pushes the compute down to the data. Data never leaves the warehouse, drastically improving performance and eliminating egress costs/security risks.
- **Complexity:** For complex imperative logic (loops, fuzzy matching, advanced JSON traversing, API integrations), Python is significantly more maintainable than hundreds of lines of declarative SQL or messy JavaScript UDFs.
- **Testing:** We can unit test Snowpark Python code locally using standard `pytest` and mock dataframes, integrating seamlessly into our CI/CD pipelines—which is notoriously difficult to do well with pure SQL.

---

## 2. When NOT to use Snowpark?

**Question:** If Snowpark is so great, why not write the entire pipeline in it? When do you choose SQL instead?

**Defense:**
- **Simple ELT:** For straight set-based operations (e.g., simple joins, aggregations, basic SCD merges), SQL (via dbt or Tasks) is faster to write, easier for analysts to read, and natively optimized by the Snowflake query engine without the Python translation overhead.
- **Data Engineering vs Analytics Engineering:** We reserve Snowpark for heavy Data Engineering workloads (e.g., complex API ingestion, feature engineering, predictive models) and keep pure transformation layers (Silver to Gold) in SQL/dbt for the Analytics Engineers.
- **"Just because we can" trap:** We don't use Snowpark just to write Python. If a problem is easily solved in declarative SQL, we use SQL. We use Snowpark when procedural logic, third-party libraries (via Anaconda), or dynamic DataFrame generation is strictly required.

---

## 3. Snowpark vs SQL?

**Question:** How does Snowpark compare to SQL under the hood? Does it run Python on every row?

**Defense:**
- **Lazy Evaluation:** Snowpark DataFrame operations do NOT run Python on every row. The Python code acts as an API that builds an Abstract Syntax Tree (AST). When an action (e.g., `.write`, `.collect()`) is called, that AST is compiled into highly optimized Snowflake SQL and executed by the standard warehouse compute.
- **UDFs/UDTFs:** The only time Python executes row-by-row is if we explicitly register a Python User Defined Function (UDF) or User Defined Table Function (UDTF). In that case, Snowflake provisions a secure Python sandbox (via Anaconda) on the warehouse nodes to execute the logic.

---

## 4. Snowpark vs PySpark?

**Question:** We already have EMR/Databricks running PySpark. Why migrate to Snowpark?

**Defense:**
- **Simplified Architecture:** We eliminate the need to manage a separate Spark cluster, Spark configurations, YARN/Kubernetes orchestration, and complex networking between the data lake and the warehouse.
- **Security:** Data stays inside Snowflake's RBAC perimeter. No temporary S3 buckets, no IAM cross-account roles just to pass data back and forth.
- **Cost:** We pay only for Snowflake virtual warehouse compute. We don't pay for idle Spark clusters or the data egress costs of pulling TBs of data out of Snowflake into Spark and pushing the results back.
- **API Similarity:** The Snowpark API was intentionally designed to mirror PySpark (DataFrames, Actions, Transformations). The migration path for our PySpark engineers is extremely low-friction.

---

## 5. Enterprise Best Practices

If asked about your specific architectural decisions in this framework:

1. **Configuration:** "We don't hardcode anything. I designed a `config_loader` using TOML and Pydantic. Environment variables dictate whether we load `dev.toml` or `prod.toml`, ensuring perfect environment isolation."
2. **Secrets:** "Credentials are never in code. In local dev we use `.env` files, but in production, our `secrets_manager` module dynamically fetches credentials via AWS Boto3 and Secrets Manager via an IAM role."
3. **Resilience:** "Networks fail. I wrap our `SnowparkSessionFactory` in the `tenacity` library to provide exponential backoff and connection retries, ensuring transient Snowflake API errors don't fail a 2-hour pipeline."
4. **Modularity:** "I strictly separate business rules from generic transformations. A transformation might be `normalize_strings()`, while a business rule is `calculate_customer_lifetime_value()`. This allows us to unit test them independently."
