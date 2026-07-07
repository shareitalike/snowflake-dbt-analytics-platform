# Platform Engineering - Terraform Enterprise Infrastructure
## Module 01 - Design Summary

### Enterprise IaC Strategy
In an enterprise, Cloud Infrastructure (AWS) and Data Infrastructure (Snowflake) cannot be managed via manual console clicks. 
We use **Terraform** as our single Source of Truth. This prevents Configuration Drift, ensures disaster recovery (RTO/RPO), and allows security teams to audit infrastructure via Pull Requests before it is deployed.

### State Management
State is NEVER stored locally. We use the `s3` remote backend for state storage (`omniretail-terraform-state-prod`), ensuring that state files are encrypted at rest via KMS. We use DynamoDB (`terraform-state-lock-prod`) to provide State Locking, preventing two engineers from applying changes to the Production environment simultaneously.

### Module Standards & FinOps
Rather than writing massive, monolithic Terraform files, we utilize highly parameterized modules. For example, our `snowflake/warehouses` module abstracts the creation of a warehouse, but strictly enforces FinOps safeguards (e.g., `statement_timeout = 3600`) to guarantee that no query can run forever and burn cloud credits.

### Environment Promotion
We maintain three environments: `dev`, `qa`, and `prod`. The `main.tf` in each environment folder simply calls the centralized modules but passes different variables. This guarantees that `prod` is architecturally identical to `dev`, eliminating the "it works on my machine" problem.
