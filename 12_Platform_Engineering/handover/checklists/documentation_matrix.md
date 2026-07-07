# Enterprise Platform Documentation Matrix

This matrix maps all major artifacts generated throughout the OmniRetail Data Platform Modernization project. It serves as a master index for the client to locate specific documentation based on their role and the technology in question.

| Artifact / Module | Phase | Technology | Purpose | Target Audience |
|-------------------|-------|------------|---------|-----------------|
| **Business Discovery Document** | Phase 02 | N/A | Captures business requirements, ROI, and KPIs. | Business Stakeholders, Execs |
| **High Level Design (HLD)** | Phase 03 | Architecture | Defines the end-to-end cloud architecture and data flow. | Enterprise Architects |
| **Enterprise Data Model** | Phase 04 | Conceptual | Defines the ERD and Data Vault / Dimensional modeling strategy. | Data Architects |
| **AWS Infrastructure (IaC)** | Phase 05 | Terraform, AWS | Provisions foundational networking, IAM, S3, and Secrets. | Cloud Engineers |
| **Snowflake Foundation** | Phase 06 | Snowflake SQL | Defines Warehouses, Databases, and initial RBAC. | Database Administrators |
| **Enterprise Security** | Phase 07 | Snowflake Gov | Implements Masking, Row Access, and Network Policies. | Security & Gov Teams |
| **CDC Framework** | Phase 08 | Snowpipe, Streams | Real-time ingestion and automated MERGE pipelines. | Data Engineers |
| **Snowpark Framework** | Phase 09 | Python | UDFs for JSON parsing, Feature Engineering, and ML prep. | Data Scientists |
| **dbt Cloud Project** | Phase 10 | dbt, SQL | T-ELT transformations (Silver to Gold), testing, and metrics. | Analytics Engineers |
| **Airflow Orchestration** | Phase 11 | Airflow (Python) | Master DAGs, custom operators, and alert routing. | Platform Engineers |
| **Enterprise CI/CD** | Phase 12 (M3) | GitHub Actions | Automated deployments with OIDC authentication. | DevOps / SRE |
| **Cost Optimization (FinOps)** | Phase 12 (M6) | Snowflake SQL | Resource Monitors, sizing, and query performance tuning. | FinOps / Platform Leads |
| **Operations Command Center** | Phase 12 (M7) | Observability | Single-pane-of-glass dashboard for platform health. | SRE / Ops |
| **Disaster Recovery (DR)** | Phase 12 (M8) | Snowflake Time Travel | RTO/RPO targets, Time Travel scripts, and DR drill plans. | SRE / DBA |
| **Production Runbooks** | Phase 12 (M9) | Operations | Daily SOPs, Incident Response (5 Whys), On-Call escalation. | L1/L2 Support, On-Call |
| **Executive Summary** | Phase 12 (M10)| Business | Final capstone summary, ROI, and Executive Presentation. | Executives, Sponsors |
| **Project Closure Report** | Phase 12 (M10)| Management | Operational readiness, Roadmap (Phase 2), and Tech Debt. | Project Managers, Leads |
