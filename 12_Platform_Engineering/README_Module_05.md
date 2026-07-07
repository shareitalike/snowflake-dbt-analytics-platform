# Phase 12 - Module 5: Enterprise Security & Governance Framework

This module enforces Enterprise Data Governance across the entire Snowflake platform, adhering strictly to Zero Trust and Least Privilege principles.

## Deliverables Checklist

- [x] **Network Policies:** Implemented `security/policies/network_policies.sql` to restrict access strictly to the corporate VPN and AWS Airflow NAT Gateways.
- [x] **Data Classification (Tags):** Built `security/tags/data_classification.sql` to systematically tag PII and sensitive data.
- [x] **Terraform Policies (Masking & Row Access):** Created Terraform modules to programmatically deploy Dynamic Data Masking (obfuscating emails) and Row Access Policies (enforcing multi-tenant regional isolation).
- [x] **RBAC Hierarchy:** Developed `security/rbac/role_hierarchy.sql` to define a strict inheritance structure linking Service Accounts (Airflow/dbt) into Functional Roles (Data Engineering), and eventually up to System Roles.
- [x] **Audit & Compliance:** Created `security/audit/access_history_queries.sql` to demonstrate how to track PII data access for GDPR/SOX compliance using Snowflake's native `ACCESS_HISTORY`.
- [x] **Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_05_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_05_Runbook.md).md) detailing Time Travel, Masking, and RBAC strategies.
