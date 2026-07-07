# Phase 12 - Module 1: Terraform Enterprise Infrastructure

This module establishes the Infrastructure as Code (IaC) foundation for the OmniRetail Data Platform. By migrating AWS and Snowflake management into Terraform, we achieve complete GitOps control over our architecture.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `terraform/modules/` and `terraform/environments/`.
- [x] **AWS Modules:** Created modular abstractions for S3 buckets, enforcing standard enterprise encryption and versioning policies.
- [x] **Snowflake Modules:** Created modular abstractions for Snowflake Warehouses, embedding FinOps best practices (auto-suspend, statement timeouts) directly into the code.
- [x] **Environment Strategy:** Created the Production environment (`environments/prod/main.tf`) utilizing an encrypted, DynamoDB-locked remote S3 state backend.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_01_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_01_Runbook.md).md) detailing why State Locking and modularity are critical.

## Usage Example (Applying Prod)
```bash
cd 12_Platform_Engineering/terraform/environments/prod
terraform init
terraform plan -out=prod_plan.tfplan
terraform apply "prod_plan.tfplan"
```
