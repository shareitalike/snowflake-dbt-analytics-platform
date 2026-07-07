# OmniRetail Enterprise Data Platform

![Architecture](https://img.shields.io/badge/Architecture-Medallion-blue.svg)
![Orchestration](https://img.shields.io/badge/Orchestration-Apache%20Airflow-red.svg)
![Transformation](https://img.shields.io/badge/Transformation-dbt%20Cloud-orange.svg)
![Compute](https://img.shields.io/badge/Compute-Snowflake-lightgrey.svg)
![Language](https://img.shields.io/badge/Language-Python%20%7C%20SQL-yellow.svg)

## 📖 Executive Summary
This repository contains the architecture, infrastructure, and data pipeline code for the **OmniRetail Enterprise Data Platform**. We migrated a legacy on-premise system that suffered from 24+ hour reporting delays, unmanaged compute spend, and data silos across 12 domains (Salesforce, Shopify, Oracle ERP, etc.) into a modern, highly-scalable cloud-native stack.

The platform is designed around a strict **Medallion architecture (Bronze -> Silver -> Gold)**, prioritizing separation of compute and orchestration, idempotent processing, and metadata-driven pipeline generation.

## 🏗️ Architecture & Data Flow

```mermaid
graph TD
    subgraph Data Sources
        S1[ERP System]
        S2[Salesforce]
        S3[eCommerce Platform]
    end

    subgraph AWS Cloud [AWS Cloud Platform]
        S3B[S3 Raw Bucket]
        SQS[SQS Notification]
        SM[Secrets Manager]
    end

    subgraph Snowflake Data Cloud [Snowflake Enterprise Edition]
        subgraph Storage Layer
            BRONZE[(Bronze / Raw)]
            SILVER[(Silver / Integration)]
            GOLD[(Gold / Analytics)]
        end
        
        subgraph Compute Layer
            INGEST_WH[Ingest WH]
            TRANSFORM_WH[Transform WH]
            BI_WH[Reporting WH]
        end
        
        subgraph Ingestion & CDC
            PIPE(Snowpipe)
            STREAM(Snowflake Streams)
            TASK(Snowflake Tasks)
        end
    end

    subgraph Transformation Engine [dbt Cloud]
        DBT_SRC[dbt Sources]
        DBT_STG[Staging Models]
        DBT_INT[Intermediate Models]
        DBT_DIM[Dimensions]
        DBT_FCT[Fact Tables]
    end

    subgraph Orchestration & CI/CD
        AIRFLOW((Apache Airflow))
        GITHUB[GitHub Actions]
        TF{Terraform}
    end

    subgraph Consumers
        PBI[Power BI]
    end

    %% Data Flow
    S1 -->|Fivetran/Custom| S3B
    S2 -->|Fivetran/Custom| S3B
    S3 -->|Fivetran/Custom| S3B
    
    S3B -->|Event Trigger| SQS
    SQS -->|Notify| PIPE
    PIPE -->|Auto-Ingest via INGEST_WH| BRONZE
    
    BRONZE -->|Track Changes| STREAM
    STREAM -->|Scheduled via| TASK
    TASK -->|MERGE via TRANSFORM_WH| SILVER
    
    SILVER -->|Reference| DBT_SRC
    DBT_SRC -->|Clean & Cast| DBT_STG
    DBT_STG -->|Join & Logic| DBT_INT
    DBT_INT -->|Build| DBT_DIM
    DBT_INT -->|Build| DBT_FCT
    DBT_DIM -->|Materialize via TRANSFORM_WH| GOLD
    DBT_FCT -->|Materialize via TRANSFORM_WH| GOLD
    
    GOLD -->|Query via BI_WH| PBI

    %% Orchestration & Deployment Flow
    AIRFLOW -.->|Trigger| TASK
    AIRFLOW -.->|API Call| Transformation Engine
    AIRFLOW -.->|Fetch| SM
    
    GITHUB -.->|Deploy Infra| TF
    TF -.->|Provision| Snowflake Data Cloud
    TF -.->|Provision| AWS Cloud
```

Our architecture enforces a strict **"Push-Down Compute"** paradigm. 
- **Orchestration (The Brain):** **Apache Airflow** (running on AWS MWAA) acts purely as an API control plane. It processes *no* data itself, ensuring workers remain lightweight and highly scalable.
- **Compute (The Muscle):** All data processing is pushed down to **Snowflake** (via Snowpark Python and dbt SQL).

### End-to-End Journey
1. **Ingestion (Bronze):** Fivetran extracts data. JSON/Parquet lands in AWS S3, triggering an SQS event. **Snowflake Snowpipe** auto-ingests this directly into the raw Bronze layer.
2. **CDC Detection:** **Snowflake Streams** track row-level inserts/updates/deletes. An Airflow sensor continuously monitors these streams and proceeds only if new data exists, preventing zero-row compute waste.
3. **Complex Processing (Silver):** Airflow triggers **Snowpark (Python)** to handle complex JSON flattening, regex normalization, and procedural business rules.
4. **Dimensional Modeling (Gold):** Airflow uses deferrable operators to trigger **dbt Cloud**, which builds Kimball dimensional models, enforces Type 2 Slowly Changing Dimensions (SCD), and runs automated Data Quality tests.
5. **Serving:** The Gold layer is consumed by Power BI via Secure Views, leveraging Dynamic Data Masking to hide PII.

## 📂 Repository Structure

- `05_AWS_Infrastructure/` - Terraform definitions for AWS components and Snowflake resources.
- `09_Snowpark_Framework/` - Python stored procedures for complex flattening and data standardization.
- `10_dbt_Project/` - dbt models (Bronze, Silver, Gold), macros, and data quality tests.
- `11_Airflow_Orchestration/` - Custom sensors, deferrable operators, and the Dynamic DAG Factory (`domain_config.yaml`).
- `12_Platform_Engineering/` - CI/CD pipelines (GitHub Actions), data observability patterns, and FinOps safeguards.
- `17_Runbooks/` - Comprehensive operational runbooks and daily SOPs.
- `docs/` - High-Level Design (HLD), Low-Level Design (LLD), and the complete project story.

## 🚀 Key Enterprise Patterns Showcased
* **Metadata-Driven Orchestration (DRY):** We eliminated boilerplate Airflow DAGs. Engineers simply update `domain_config.yaml`, and our factory auto-generates the tasks and dependencies in memory.
* **FinOps Safeguards:** Prevented runaway Snowflake queries using Terraform-enforced `statement_timeout_in_seconds = 3600` and stream-checks before resuming warehouses.
* **Data Quality & Quarantining:** Implemented a Dead Letter Queue (DLQ) pattern where malformed Bronze records are quarantined automatically, triggering Slack alerts instead of failing the pipeline.

## 📚 Documentation
For a deep dive into the business problems solved, operational workflows, and the complete step-by-step project flow, please see:
* [Comprehensive Operations Runbook](17_Runbooks/comprehensive_runbook.md)
* [Full Project Flow & Story](docs/project_flow_story.md)
