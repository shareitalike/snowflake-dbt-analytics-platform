# Resume Mapping: Enterprise Data Ingestion

Add these bullet points to your resume to highlight your expertise in data movement:

## Senior Data Engineer Bullets:
* Engineered a serverless, event-driven Change Data Capture (CDC) ingestion framework using **Snowflake Snowpipe** and **AWS SNS/SQS**, reducing raw data latency from 24 hours to sub-minute SLAs.
* Designed and implemented an automated **Dead Letter Queue (DLQ)** routing system utilizing Snowflake Stored Procedures and `COPY_HISTORY` metadata, ensuring 100% data durability during schema drift events.
* Transitioned legacy rigid ETL pipelines to a modern **Schema-on-Read** architecture, ingesting deeply nested JSON and CSV payloads into Bronze `VARIANT` columns to completely eliminate pipeline downtime caused by upstream API changes.

## Principal Architect Bullets:
* Architected the enterprise ingestion control plane, decoupling file arrival from compute by utilizing Snowflake's serverless micro-batch capabilities, resulting in a ~40% reduction in `INGEST_WH` compute costs.
* Designed the operational observability semantic layer, providing DataOps teams with real-time views into pipe latency, file validation errors, and SLA breaches via Snowflake `INFORMATION_SCHEMA`.
