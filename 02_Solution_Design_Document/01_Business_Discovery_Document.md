# OmniRetail Group: Enterprise Data Platform Modernization - Phase 0 Discovery & Strategy
**Date:** December 10, 2024
**Prepared By:** Enterprise Data Consulting Team (Principal Architecture Group)
**Client:** OmniRetail Group 
**Project:** Enterprise Data Platform Modernization
**Status:** Approved - Baseline Version 3.0 (Enterprise Architecture)

---

## 1. Executive Summary
OmniRetail Group, a Fortune 500 global e-commerce and brick-and-mortar enterprise, requires a highly governed, low-latency enterprise data platform to consolidate disjointed operational systems. The current architecture suffers from severe data silos across 12 distinct domains, uncontrolled compute spend, and compliance vulnerabilities. This engagement (Dec 2024 - Aug 2025) will deliver a production-grade Medallion architecture (Bronze, Silver, Gold) on Snowflake. We will utilize Apache Airflow for enterprise orchestration, dbt Cloud for dimensional modeling, Snowpark for complex procedural logic, and AWS S3/Snowpipe for near-real-time Change Data Capture (CDC). The target state will guarantee zero-trust data governance, enforce CI/CD deployment standards via GitHub Actions, and introduce comprehensive data observability.

## 2. Business & Technical Problems
OmniRetail operates in highly fragmented domains. Finance relies on Oracle ERP extracts, E-commerce analyzes Shopify logic, and Store Operations pulls POS reports—all executing localized, non-version-controlled transformations. This decentralization creates profound semantic inconsistencies (e.g., conflicting definitions of "Net Revenue"), eroding C-suite trust. Furthermore, the absence of a unified Slowly Changing Dimension (SCD) strategy prevents point-in-time historical analysis. From a compliance standpoint, Personally Identifiable Information (PII) is currently stored in plaintext and accessible to broad engineering roles, violating GDPR/CCPA regulations and internal Infosec policies.

## 3. Projected Business Impact
The modernization initiative is tied directly to the following measurable business outcomes:
* **Reduced Reporting Latency:** Shrinking data availability timelines from ~24 hours to under 15 minutes via micro-batch CDC.
* **Standardized KPI Definitions:** Establishing a single, immutable source of truth for all departments.
* **Operational Efficiency:** Reducing manual financial and inventory reconciliation effort by ~70%.
* **Data Reliability:** Dramatically improving data quality through automated validation, quarantine patterns, and DLQs.
* **Cost Predictability:** Optimizing Snowflake compute consumption through strict warehouse isolation and incremental dbt processing.

## 4. Enterprise Business Domains
To fulfill the Fortune 500 mandate, the platform will ingest, standardize, and conform data across the following source systems:

| Domain | Source System |
| :--- | :--- |
| **Customer** | Salesforce CRM |
| **Sales (Digital)** | Shopify |
| **Store Sales (Retail)** | Point of Sale (POS) Systems |
| **Finance** | Oracle ERP |
| **Payments** | Stripe |
| **Inventory** | Manhattan WMS (Warehouse Management System) |
| **Supplier** | Supplier Portal |
| **Marketing** | Adobe / Google Marketing Platform |
| **Customer Support** | Zendesk |
| **Product Master** | PIM (Product Information Management) |
| **Vendor Files** | SFTP (CSV / Parquet Extracts) |
| **External APIs** | REST APIs (Logistics / Shipping Partners) |

## 5. Strategic Objectives & Scope of Work
* **Unified Semantic Layer (dbt Cloud):** Develop a Medallion architecture (Staging, Intermediate, Marts). Implement a Quarantine (Dead Letter Queue) pattern in the Bronze layer to isolate malformed records. Enforce idempotent incremental models and comprehensive data quality testing.
* **Enterprise Orchestration (Apache Airflow):** Apache Airflow will serve as the overarching enterprise orchestration layer coordinating source ingestion, Snowpipe validation, Snowpark transformations, dbt Cloud jobs, operational monitoring, SLA checks, and downstream Power BI semantic layer refreshes.
* **Advanced Transformations (Snowpark):** Leverage Snowpark Python for procedural, non-SQL workloads, specifically: Schema Validation, Data Standardization, Reference Data Matching, Business Rule Engine execution, Duplicate Detection, Address Normalization, and Complex JSON Flattening.
* **Near Real-Time Ingestion:** Implement AWS S3 to Snowpipe Auto-Ingest utilizing SQS event notifications for micro-batch CDC processing.
* **Enterprise Data Governance:** Deploy Snowflake Object Tagging for automated PII classification and warehouse cost attribution. Enforce Dynamic Data Masking Policies (e.g., SHA256 hashing) and Row Access Policies. Materialize all Gold-layer models exclusively as Secure Views for Power BI consumption.

## 6. Architecture Decision Records (ADR)
To document and defend our technical choices, the following ADRs have been established:

* **ADR-001: Why Snowpipe instead of COPY INTO?** 
  * *Decision:* Snowpipe Auto-Ingest provides event-driven, continuous micro-batch loading without managing dedicated compute warehouses, drastically reducing CDC latency to <15 mins.
* **ADR-002: Why dbt instead of Stored Procedures?**
  * *Decision:* dbt Cloud enforces software engineering best practices (version control, CI/CD, modular SQL, automated testing, and lineage documentation) which legacy stored procedures lack, enabling scalable Analytics Engineering.
* **ADR-003: Why Snowpark for Business Rules?**
  * *Decision:* Python inside Snowpark allows for procedural logic (e.g., regex-heavy address normalization, REST API payload flattening) that is either impossible or highly inefficient in pure SQL, while keeping execution pushed down to Snowflake compute.
* **ADR-004: Why Bronze, Silver, Gold (Medallion)?**
  * *Decision:* It provides a logical progression of data cleanliness. Bronze guarantees an immutable audit trail; Silver provides conformed, standardized entities; Gold delivers business-ready Kimball dimensional models.
* **ADR-005: Why Separate Warehouses?**
  * *Decision:* Total workload isolation. `INGEST_WH` will not compete with `TRANSFORM_WH` or `BI_REPORTING_WH`, eliminating resource contention and preventing a heavy dbt run from slowing down executive dashboards.
* **ADR-006: Why Type 2 Customer History?**
  * *Decision:* Business users must analyze revenue based on the customer's region/tier *at the exact time of the transaction*. Overwriting records (Type 1) destroys this historical accuracy.

## 7. Slowly Changing Dimension (SCD) Strategy
We will implement explicit historical tracking logic via dbt snapshots and MERGE statements aligned to the following matrix:

| Dimension | Strategy | Rationale |
| :--- | :--- | :--- |
| **Customer** | SCD Type 2 | Must track tier upgrades, address changes, and segment shifts over time. |
| **Product** | SCD Type 2 | Must track historical pricing and category re-alignments. |
| **Store** | SCD Type 2 | Must track store format changes and regional manager reassignments. |
| **Employee** | SCD Type 2 | Must track role promotions and department transfers. |
| **Currency** | SCD Type 1 | Only current FX rate is required for real-time localized display (historical rates kept in a fact table). |
| **Country** | SCD Type 1 | Borders and naming conventions update globally; history tracking provides no business value. |
| **Calendar** | Static | Dates do not change. |

## 8. Operational Monitoring Framework
A critical deliverable for this engagement is the comprehensive observability suite. We will deliver an Operational Monitoring Framework tracking:
* **Pipeline Execution History:** Airflow DAG completion times and task bottlenecks.
* **Warehouse Credit Usage:** Granular Snowflake spend tracking via Resource Monitors and Object Tags.
* **Snowpipe History:** Tracking ingestion latency and file validation errors.
* **Task History:** Monitoring background Snowflake maintenance tasks.
* **Load History:** Validating total rows ingested vs. total rows generated at source.
* **Data Freshness SLA:** Alerting via Slack/SNS if Gold layer tables fall > 15 minutes behind.
* **DQ Scorecards:** Tracking the pass/fail rate of generic and singular dbt tests.
* **Error Dashboard:** Centralized view of the DLQ / Quarantine volumes across all domains.

## 9. Success Criteria
* **Latency:** Data freshness SLA of < 15 minutes from source generation to Bronze layer availability.
* **Governance:** 100% of defined PII fields masked dynamically based on the querying user's active role.
* **Performance:** 95th percentile query execution time for Power BI dashboard refreshes under 3 seconds.
* **Reliability:** Zero un-alerted data pipeline failures reaching production. Guaranteed via automated dbt testing, Airflow SLA alerting (Slack/SNS integration), and a robust quarantine strategy.

## 10. Future Roadmap (Post-Phase 1)
To ensure the platform remains future-proof, Phase 2 initiatives will include:
* **Snowflake Cortex Analyst:** Enabling LLM-powered natural language querying on top of the Gold semantic layer.
* **Apache Iceberg Tables:** Abstracting storage for vendor interoperability and open data formats.
* **Snowpipe Streaming:** Upgrading from micro-batch SQS to sub-second streaming for IoT/POS inventory telemetry.
* **Semantic Models:** Defining universal metrics logically in dbt to feed headless BI tools.
* **Data Marketplace:** Monetizing anonymized retail trend data via Snowflake Secure Data Sharing.
* **Native Apps:** Developing bespoke inventory forecasting applications executing directly within the Snowflake perimeter.
