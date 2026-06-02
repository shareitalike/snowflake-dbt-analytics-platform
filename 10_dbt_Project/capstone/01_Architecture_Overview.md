# Enterprise Architecture Overview

This document illustrates the complete end-to-end architecture of the OmniRetail Enterprise Data Platform, bridging raw data ingestion to executive analytics.

## Complete Data Lineage

```mermaid
graph TD
    subgraph Source Systems
        S1[(Shopify REST API)]
        S2[(Oracle ERP)]
        S3[(Zendesk)]
    end

    subgraph Data Ingestion [Phase 07]
        I1[Fivetran / Kafka Connect]
        I2[HVR CDC]
        
        S1 --> I1
        S2 --> I2
    end

    subgraph Bronze Layer [Snowflake RAW - Phase 08]
        B1[(RAW.SHOPIFY_ORDERS)]
        B2[(RAW.ORACLE_INVENTORY)]
        
        I1 --> B1
        I2 --> B2
    end

    subgraph Silver Layer [dbt Staging - Phase 10]
        STG1(stg_shopify_orders)
        STG2(stg_oracle_inventory)
        
        B1 -- dbt Source Freshness --> STG1
        B2 -- Snowpark Quality Validation --> STG2
    end

    subgraph Silver Layer [dbt Intermediate]
        INT1(int_orders_enriched)
        INT2(int_inventory_reconciled)
        
        STG1 -- Surrogate Keys & Deduplication --> INT1
        STG2 -- Type Casting --> INT2
    end

    subgraph Gold Layer [dbt Marts]
        DIM1[[dim_customer <br> SCD Type 2 Snapshot]]
        FCT1[[fct_sales <br> Incremental MERGE]]
        
        INT1 -- dbt Tests Enforced --> DIM1
        INT1 --> FCT1
        INT2 --> FCT1
    end

    subgraph Delivery [Semantic & Exposures]
        SEM(dbt Semantic Layer <br> 'net_revenue_metric')
        PBI>Power BI Executive Dashboard]
        
        FCT1 -.-> SEM
        SEM --> PBI
    end
```

## Complete Repository Structure
The dbt project is structured following enterprise best practices:
```text
10_dbt_Project/
├── analyses/              # Ad-hoc analytical queries
├── catalog/               # Business glossary and semantic metrics
├── docs/                  # Architectural decision records (ADRs)
├── exposures/             # Downstream consumer mappings
├── governance/            # Data contracts and ownership matrices
├── lineage/               # Lineage diagrams
├── macros/                # Reusable Jinja functions (utilities, audit, dates)
├── models/
│   ├── staging/           # 1:1 view of raw sources with standardized naming
│   ├── intermediate/      # Business logic, joining, surrogate key generation
│   ├── marts/
│   │   ├── dimensions/    # Conformed Kimball dimensions
│   │   └── facts/         # Granular transactional facts
│   └── incremental/       # Highly optimized delta models (MERGE / INSERT_OVERWRITE)
├── seeds/                 # Static reference data (e.g., currency_codes.csv)
├── snapshots/             # SCD Type 2 automated historical tracking
├── tests/
│   ├── generic/           # Reusable parameter-driven test macros
│   └── singular/          # Complex multi-table SQL assertions
├── dbt_project.yml        # Core configuration and materialization strategy
└── packages.yml           # Dependencies (dbt_utils, dbt_expectations)
```
