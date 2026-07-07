# Module 3: Enterprise Tasks Framework

## Overview
This module implements the native Snowflake Task DAG (Directed Acyclic Graph) responsible for orchestrating the CDC pipelines. By utilizing Snowflake Tasks, we achieve highly concurrent, dependency-aware orchestration without the overhead of an external tool like Airflow for micro-batch execution.

## Framework Components
* `04_tasks.sql`: Contains the physical definitions of the Root Task, 8 concurrent Child Tasks, the dependent Tasks (`TSK_CDC_ORDERS`), and the final Consolidation/Metadata Tasks.
* `05_task_monitoring_views.sql`: Exposes the internal `TASK_HISTORY` table function to provide simple SLA alerting and failure tracing.
* `06_task_rollback_scripts.sql`: Safe suspension scripts for emergency pauses.

## Warehouse Optimization
* **SERVERLESS Compute**: Utilized for the Root Task (`TSK_CDC_MASTER_SCHEDULE`) and Metadata update tasks. Since these tasks only perform triggering or lightweight inserts (no data transformations), the Serverless model is extremely cost-efficient.
* **PROVISIONED Compute**: Utilized for the CDC child tasks (`WH_TRANSFORM`). Because we execute 5+ child tasks concurrently in the DAG, a dedicated warehouse ensures we can leverage parallel threads (or Multi-Cluster scaling) to complete the `MERGE` statements rapidly.

## FinOps Strategy
Every single child task is wrapped with a `WHEN SYSTEM$STREAM_HAS_DATA(...)` condition. If the 15-minute schedule triggers but there is no new data from Snowpipe, the task silently skips. **Crucially, the warehouse is never spun up.** This prevents wasting credits on empty executions during off-peak retail hours.
