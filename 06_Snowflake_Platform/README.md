# Snowflake Infrastructure as Code (IaC)

## Overview
This repository contains the physical DDL implementation of the OmniRetail Group Snowflake Platform. It rigidly follows the architectural standards defined in `01_Snowflake_Platform_Design.md`, establishing strict workload isolation, enterprise RBAC, Zero-Trust governance (Dynamic Data Masking / Row Access Policies), and modular environments.

## Repository Structure
```text
06_Snowflake_Platform/src/
├── 01_rbac/              # Roles, Hierarchy, Users
├── 02_compute/           # Warehouses, Resource Monitors
├── 03_storage/           # Databases, Schemas
├── 04_security/          # Grants, Future Grants
├── 05_integration/       # Storage Integrations, External Stages, File Formats
├── 06_governance/        # Tags, Masking Policies, Row Access Policies
├── 07_observability/     # Pipeline Logs, Quarantine Tables
└── 08_pipelines/         # Streams, Tasks, Dynamic Tables
```

## Deployment Order
To avoid dependency failures, scripts must be executed as `ACCOUNTADMIN` (or heavily elevated roles) in strict sequential order:

1. **`01_rbac`**: Establish the SYSADMIN / SECURITYADMIN delegation and base functional roles.
2. **`02_compute`**: Deploy Resource Monitors before assigning them to Warehouses.
3. **`03_storage`**: Scaffold the logical Medallion databases and domain schemas.
4. **`04_security`**: Map the base roles (from step 1) to the schemas (from step 3).
5. **`05_integration`**: Establish AWS trust. (Note: Run `DESCRIBE INTEGRATION` after `01_storage_integrations.sql` to retrieve IAM ARN for the AWS Terraform module).
6. **`06_governance`**: Deploy Masking Policies to the `DB_PROD_GOVERNANCE` database.
7. **`07_observability` & `08_pipelines`**: Scaffold the operational metadata tables.

## Best Practices
* **Idempotency**: All scripts use `CREATE IF NOT EXISTS` or `CREATE OR REPLACE` to allow safe, repeated execution in CI/CD pipelines (e.g., SchemaChange, Flyway).
* **Future Grants**: `04_security/02_future_grants.sql` is critical. It guarantees that when dbt rebuilds models from scratch, business analysts do not lose access to the new views.
* **Service Accounts**: `SVC_AIRFLOW` and `SVC_DBT_CLOUD` are created without passwords, enforcing RSA Key-Pair authentication in production environments.
