# OmniRetail Enterprise Data Platform - Project Story & Flow

## 📖 The Story: Why We Built This
OmniRetail (a Fortune 500 company) struggled with data silos across 12 different domains (Salesforce, Shopify, Oracle ERP, etc.). Their legacy system was plagued by reporting delays (24+ hours), inconsistent KPI definitions, uncontrolled Snowflake compute costs, and a lack of proper historical tracking. 

To solve this, we designed a **modern, decoupled, cloud-native data platform** centered around a strict Medallion architecture (Bronze -> Silver -> Gold).

## 🏗️ The Core Architecture (The Flow)

The data journey follows a strictly orchestrated path, managed globally by **Apache Airflow (AWS MWAA)**. *Crucially, Airflow never processes data; it acts purely as the brain, issuing API commands.*

### Step 1: Ingestion & Landing (Bronze)
1. **Fivetran** extracts raw data from operational systems (e.g., Salesforce, Oracle).
2. Data lands as JSON/Parquet in **AWS S3** (`s3://omniretail-bronze-prod`).
3. S3 immediately emits an event to **AWS SQS**.
4. **Snowflake Snowpipe** is triggered by SQS and automatically ingests the raw data into Snowflake Bronze tables.

### Step 2: Detection & Streaming (CDC)
1. Instead of full table scans, **Snowflake Streams** track changes (Inserts/Updates/Deletes) in the Bronze layer.
2. A custom **Airflow Sensor** continuously monitors these streams. It only proceeds if `SYSTEM$STREAM_HAS_DATA()` returns true, preventing zero-row processing and saving compute costs.

### Step 3: Complex Transformations (Silver)
1. Airflow triggers a **Snowpark (Python)** stored procedure.
2. Snowpark pushes down compute to Snowflake to handle complex JSON flattening, regex normalization, and business rule execution.
3. The cleaned, flattened data is pushed into the Silver layer.

### Step 4: Dimensional Modeling (Gold)
1. Airflow uses a deferrable operator to trigger **dbt Cloud**.
2. dbt Cloud runs `dbt build`, executing SQL transformations to build the Gold layer (Kimball dimensional models).
3. This step enforces **Slowly Changing Dimensions (SCD Type 2)** for historical tracking (e.g., tracking a customer's changing address over time) and runs automated Data Quality tests.

### Step 5: Serving (Consumption)
1. The Gold layer tables are exposed as **Secure Views**.
2. Downstream BI tools like **Power BI** consume these views, utilizing Dynamic Data Masking to hide PII based on user roles.

## 🚀 How to Execute & Work on this Project

If you are a Data Engineer on this project, here is how you interact with the system:

1. **Infrastructure (Terraform):** You do not click around the UI. All Snowflake warehouses, roles, and AWS resources are defined in Terraform.
2. **Orchestration (Airflow):** You do not write boilerplate Python DAGs. You add a 10-line YAML configuration to `domain_config.yaml`, and our **Dynamic DAG Factory** auto-generates the Airflow DAG for you.
3. **Transformations (dbt):** You write modular SQL in dbt Cloud, define tests in `schema.yml`, and open PRs. CI/CD (GitHub Actions) validates your code before it merges.
4. **Monitoring:** You monitor the platform using the Daily SOP Runbook and the observability dashboards.

> [!TIP]
