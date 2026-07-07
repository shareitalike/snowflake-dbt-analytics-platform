# Phase 12 - Module 2: Enterprise Snowflake Infrastructure as Code

This module expands our Terraform footprint directly into the Data Warehouse. By utilizing the official Snowflake-Labs Terraform provider, we manage all warehouses, databases, roles, and FinOps monitors entirely in code.

## Deliverables Checklist

- [x] **Repository Structure:** Populated `terraform/snowflake/`.
- [x] **Provider Configuration (`versions.tf`, `provider.tf`):** Pinned the exact Snowflake provider version to prevent unexpected API breakages.
- [x] **Database Modules:** Built modules to dynamically generate the Medallion architecture (BRONZE, SILVER, GOLD) per environment.
- [x] **Security & Governance (Roles & RBAC):** Implemented programmatic Role-Based Access Control, ensuring users inherit permissions safely through functional roles rather than direct grants.
- [x] **Resource Monitors (FinOps):** Created automated budget tracking that forcefully suspends warehouses if they breach their monthly credit quota.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_02_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_02_Runbook.md).md).

## Usage Example (RBAC in Terraform)
```hcl
resource "snowflake_role_grants" "eng_to_sysadmin" {
  role_name = snowflake_role.data_eng.name
  roles     = [snowflake_role.sysadmin.name]
}
```
