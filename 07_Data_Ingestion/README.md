# Data Ingestion (Snowpipe CDC) Module

## Overview
This module implements the event-driven Change Data Capture (CDC) framework for the OmniRetail Data Platform. It replaces batch processing with continuous, sub-minute ingestion via Snowflake **Snowpipe** coupled with AWS **SNS/SQS**.

## Components
* `01_raw_tables.sql`: Physical instantiation of the Bronze tier. Uses `VARIANT` columns for schema-on-read flexibility.
* `02_snowpipes.sql`: The actual `CREATE PIPE` DDL. Crucially, uses `ON_ERROR = CONTINUE` to prevent poison-pill records from halting the ingestion micro-batch.
* `03_error_handling.sql`: A Javascript Stored Procedure designed to automatically parse `COPY_HISTORY`, identify failed files, force a replay, and route persistently failing payloads into a Quarantine/Dead Letter Queue (DLQ).
* `04_monitoring.sql`: Semantic views laid over Snowflake's `INFORMATION_SCHEMA` to allow Airflow and Datadog to poll for ingestion SLAs.

## Deployment Instructions
1. Ensure the AWS Infrastructure (Phase 05) and Snowflake Platform (Phase 06) are fully deployed.
2. Deploy `01_raw_tables.sql`.
3. Deploy `02_snowpipes.sql`. Note: You MUST update the `AWS_SNS_TOPIC` ARN with the exact topic created by Terraform in the previous phase.
4. Run `SELECT SYSTEM$PIPE_STATUS('<pipe_name>')` to verify the SNS subscription is active.

## Error Handling Philosophy
We do not abort transactions on schema drift. Bad records are skipped (`ON_ERROR = CONTINUE`). The `SP_REPLAY_FAILED_FILES` procedure sweeps behind the pipes to route these bad records into `DB_PROD_RAW.SC_BRONZE_QUARANTINE.TB_DLQ_PAYLOADS` for data stewards to investigate without impacting downstream analytics.
