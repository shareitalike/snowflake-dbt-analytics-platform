# Enterprise Airflow Platform Architecture

## Design Summary

### Why Apache Airflow?
In a Fortune 500 Retail environment, data pipelines are incredibly heterogeneous. We ingest data from AWS S3, execute Snowflake SQL, trigger external REST APIs (e.g., Salesforce), and compile dbt models. A "single pane of glass" is required to orchestrate these highly dependent, cross-platform workloads. Apache Airflow (via Managed Workflows for Apache Airflow - MWAA, or Astronomer) provides the industry-standard, Python-based DAG (Directed Acyclic Graph) engine required to orchestrate this complexity at scale.

### Airflow vs. Snowflake Tasks vs. dbt Jobs
- **Snowflake Tasks:** Excellent for purely internal Snowflake operations (e.g., CDC Streams -> MERGE). However, Snowflake Tasks cannot trigger an AWS Lambda function or run a custom Python script to hit an external API.
- **dbt Cloud Jobs:** Excellent for scheduling dbt models. However, a dbt Job cannot pause to wait for an AWS S3 file to arrive, nor can it alert a PagerDuty API if a non-dbt ingestion pipeline fails.
- **Apache Airflow:** The "Control Plane." Airflow does *not* process data. It acts as the macro-orchestrator. It senses the S3 file, triggers the Snowflake Task, triggers the dbt Cloud Job, and monitors the overall SLA.

## Complete Platform Lineage

```mermaid
graph TD
    subgraph External Systems
        AWS[AWS S3 / API Gateway]
        API[External REST APIs]
    end

    subgraph Orchestration Layer
        AIRFLOW((Apache Airflow))
    end

    subgraph Ingestion & Bronze Layer
        SP[Snowpipe]
        STR[Snowflake Streams]
        TSK[Snowflake Tasks]
    end

    subgraph Silver & Gold Layer
        SNOW[Snowpark Validations]
        DBT[dbt Cloud Transformations]
    end

    subgraph Presentation
        PBI>Power BI Dashboards]
    end

    %% Orchestration Flows
    AIRFLOW -. 1. S3 Sensor .-> AWS
    AWS --> SP
    SP --> STR
    
    AIRFLOW -. 2. Trigger .-> TSK
    STR --> TSK
    
    AIRFLOW -. 3. Trigger .-> SNOW
    TSK --> SNOW
    
    AIRFLOW -. 4. Trigger .-> DBT
    SNOW --> DBT
    
    AIRFLOW -. 5. Refresh .-> PBI
    DBT --> PBI
```

## Environment Strategy
Airflow environments are strictly isolated to ensure stability:
- **Development (`dev`):** Runs locally via Docker (`astro dev start`). Developers test DAG syntax and Python logic without impacting shared resources. Connects to the Snowflake `DEV` database.
- **QA/Staging (`qa`):** A persistent, cloud-hosted Airflow environment. Code is deployed here via GitHub Actions for integration testing against production-volume data.
- **Production (`prod`):** Highly available cloud deployment (MWAA/Astronomer). Strict RBAC (Role-Based Access Control). No manual DAG triggers allowed unless responding to an incident via a break-glass role.

## Deployment Strategy
We utilize **CI/CD via GitHub Actions**:
1. **Linting & Testing:** On Pull Request, `flake8`, `black`, and `pytest` validate the DAG syntax.
2. **DAG Integrity Check:** A script ensures all DAGs compile successfully and contain no cyclic dependencies (`airflow dags test`).
3. **Automated Promotion:** Upon merge to `main`, GitHub Actions zips the `dags/` and `plugins/` directories and deploys them to the Production Airflow bucket/environment.

## Security & Logging Strategy
- **Security:** Airflow Connections (credentials) are NEVER stored in plaintext in the Airflow UI. We use **AWS Secrets Manager** as the Airflow Secrets Backend. When a DAG requests the `snowflake_default` connection, Airflow retrieves the rotating credential dynamically from AWS.
- **Logging:** All Task logs are forwarded to **Datadog** (or AWS CloudWatch) to provide centralized, searchable log retention compliant with SOC2 auditing requirements.
- **Monitoring:** Airflow emits StatsD metrics. If a critical DAG (e.g., `daily_revenue_load`) fails, the `on_failure_callback` triggers a Slack Operator and creates a PagerDuty incident automatically.
