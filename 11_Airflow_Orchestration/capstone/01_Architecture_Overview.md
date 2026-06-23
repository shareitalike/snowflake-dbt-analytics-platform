# Capstone Module: Enterprise Architecture Overview

The following diagram illustrates the complete, end-to-end Enterprise Data Platform architecture we have built across all 11 phases of this project. Apache Airflow acts as the central "Brain" (Control Plane), coordinating compute (Muscle) across AWS, Snowflake, Snowpark, and dbt Cloud.

```mermaid
graph TD
    %% Define styles
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:black
    classDef snowflake fill:#29B5E8,stroke:#1A6B8C,stroke-width:2px,color:white
    classDef airflow fill:#017CEE,stroke:#01529D,stroke-width:3px,color:white
    classDef dbt fill:#FF694B,stroke:#C24D35,stroke-width:2px,color:white
    classDef bi fill:#F2C811,stroke:#A68900,stroke-width:2px,color:black

    %% Flow
    S3[AWS S3 Bronze Zone]:::aws -->|SQS Notifications| SP[Snowpipe Auto-Ingest]:::snowflake
    SP --> BRONZE[(Snowflake Bronze: Raw JSON)]:::snowflake
    BRONZE --> STRM[Snowflake CDC Streams]:::snowflake
    STRM -->|Airflow Stream Sensor| TASK[Snowflake Tasks]:::snowflake
    TASK -->|Airflow Snowpark Trigger| PARK[Snowpark: Flattening]:::snowflake
    PARK --> SILVER[(Snowflake Silver: Cleaned)]:::snowflake
    SILVER -->|Airflow dbt Cloud Job| DBT[dbt Build / Test]:::dbt
    DBT --> GOLD[(Snowflake Gold: Business)]:::snowflake
    GOLD -->|Airflow PowerBI Operator| PBI[Power BI Dashboards]:::bi
    
    %% Airflow Control Box
    subgraph Control_Plane [Apache Airflow Control Plane]
        direction LR
        DAG[Master DAG]:::airflow
        MONITOR[Prometheus Metrics]:::airflow
        ALERT[Enterprise Alert Router]:::airflow
    end

    %% Airflow Connections
    DAG -. Triggers & Monitors .-> SP
    DAG -. Triggers & Monitors .-> TASK
    DAG -. Triggers & Monitors .-> PARK
    DAG -. Triggers & Monitors .-> DBT
    DAG -. Triggers & Monitors .-> PBI
```

### Strategic Separation of Concerns
1. **No Data Processing in Airflow:** Notice that Airflow handles zero rows of data. It issues commands (SQL, API calls) and listens for success. 
2. **Compute Localization:** Snowpark processes data natively inside Snowflake (no egress). dbt Cloud compiles SQL and pushes it to Snowflake.
3. **Resilience:** If Snowflake crashes, the Airflow `EnterpriseSnowflakeOperator` automatically catches the failure and routes it through the `EnterpriseAlertRouter` to PagerDuty.
