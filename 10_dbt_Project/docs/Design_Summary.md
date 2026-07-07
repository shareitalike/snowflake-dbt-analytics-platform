# Enterprise dbt Cloud Project
## Module 1 - Design Summary

### Why dbt and Analytics Engineering?
In traditional ETL paradigms (Informatica, DataStage), business logic is locked away in proprietary GUI tools, making version control, code review, and automated testing extremely difficult. **Analytics Engineering**, powered by **dbt (data build tool)**, brings software engineering best practices to SQL development. 
- **Why ELT over ETL?** The massive compute power of Snowflake allows us to Extract and Load raw data quickly, and Transform it *in-place*. dbt orchestrates these in-place transformations via Pushdown SQL.
- **Why Modular SQL?** Instead of monolithic 1,000-line stored procedures, dbt breaks logic into small, testable, DRY (Don't Repeat Yourself) components via Jinja macros and the `{{ ref() }}` function.

### The Medallion Architecture (dbt mapping)
1. **Bronze (Raw Data):** Ingested via Snowpipe/CDC (Phase 7 & 8).
2. **Silver (Staging/Intermediate):** Cleaned, deduplicated, and typed by dbt `staging` and `intermediate` models.
3. **Gold (Marts):** Fully aggregated, Kimball-modeled `facts` and `dimensions` designed explicitly for Power BI.

### Project Architecture & Dependency Graph

```mermaid
graph TD
    subgraph Sources (Raw / Bronze)
        S1[raw_shopify.orders]
        S2[raw_shopify.customers]
    end

    subgraph Staging (Silver 1)
        STG1[stg_shopify__orders]
        STG2[stg_shopify__customers]
    end

    subgraph Intermediate (Silver 2)
        INT1[int_orders_joined_customers]
    end

    subgraph Marts (Gold)
        DIM1[dim_customers]
        FACT1[fct_orders]
    end

    subgraph Exposures (BI)
        PBI[Power BI Sales Dashboard]
    end

    S1 --> STG1
    S2 --> STG2
    STG1 --> INT1
    STG2 --> INT1
    INT1 --> FACT1
    STG2 --> DIM1
    FACT1 --> PBI
    DIM1 --> PBI

    classDef source fill:#f9e79f,stroke:#f1c40f,stroke-width:2px;
    classDef staging fill:#d6eaf8,stroke:#3498db,stroke-width:2px;
    classDef int fill:#d1f2eb,stroke:#1abc9c,stroke-width:2px;
    classDef mart fill:#f5b041,stroke:#e67e22,stroke-width:2px;
    
    class S1,S2 source;
    class STG1,STG2 staging;
    class INT1 int;
    class DIM1,FACT1 mart;
```

### Materialization Strategy
- **View (`view`):** Used for Staging models. Fast to build, zero storage cost, pushes compute downstream.
- **Ephemeral (`ephemeral`):** Used for Intermediate components. Compiles directly into downstream queries via CTEs. Does not physically exist in Snowflake.
- **Table (`table`):** Used for Dimensions. Fast querying in BI tools. Fully rebuilt on each run.
- **Incremental (`incremental`):** Used for large Fact tables. Only processes new records (using `MERGE`), drastically reducing Snowflake compute costs.
- **Snapshot (`snapshot`):** Used for Type 2 Slowly Changing Dimensions (SCD2) to track historical state changes over time.
