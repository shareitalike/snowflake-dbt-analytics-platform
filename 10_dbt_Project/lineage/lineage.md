# Enterprise Data Lineage

The following diagram illustrates the complete end-to-end data lineage, from raw source extraction to downstream Power BI exposure, including column-level conceptual tracking.

```mermaid
graph TD
    subgraph Upstream Sources
        S1[(Shopify API)]
        S2[(Oracle ERP)]
    end

    subgraph Bronze Layer [Snowflake RAW/CDC]
        R1[RAW.SHOPIFY.ORDERS]
        R2[RAW.ORACLE.INVENTORY]
        S1 -- Fivetran/Kafka --> R1
        S2 -- HVR --> R2
    end

    subgraph Silver Layer [dbt Staging & Intermediate]
        STG1(stg_orders)
        STG2(stg_inventory)
        INT1{int_orders_enriched}
        
        R1 -- dbt_utils.deduplicate --> STG1
        R2 -- try_cast() --> STG2
        STG1 -- Join Logic --> INT1
    end

    subgraph Gold Layer [dbt Marts]
        FCT1[[fct_sales]]
        DIM1[[dim_product]]
        
        INT1 -- Contract Enforced --> FCT1
        STG2 -- SCD2 Snapshot --> DIM1
    end
    
    subgraph Semantic Layer
        M1((net_revenue_metric))
        FCT1 -. Column Level Lineage (net_revenue) .-> M1
    end

    subgraph Downstream Exposures
        EXP1>Exec KPI Dashboard (Power BI)]
        EXP2>Inventory ML Model (SageMaker)]
        
        M1 --> EXP1
        FCT1 --> EXP1
        DIM1 --> EXP2
    end
```
