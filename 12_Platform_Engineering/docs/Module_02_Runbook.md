# Operational Runbook: Snowflake IaC

## Common Production Issues

### 1. Provider Version Changes (State Drift)
**Symptom:** Running `terraform plan` results in an error about unsupported attributes on `snowflake_warehouse`.
**Root Cause:** The Snowflake-Labs provider was updated to a new major version, deprecating an attribute.
**Resolution:**
We strictly pin the provider version in `providers/versions.tf` (`version = "~> 0.73"`). If an upgrade is required, it must be explicitly tested in the `dev` environment first.

### 2. Grant Conflicts (Manual vs Terraform)
**Symptom:** `terraform apply` fails when trying to apply a `snowflake_role_grants` resource, stating the grant already exists.
**Root Cause:** A DBA manually ran `GRANT ROLE PROD_DATA_ENGINEER_ROLE TO USER JSMITH` in the Snowflake UI instead of updating the Terraform code.
**Resolution:**
Terraform expects to be the sole source of truth. You must either import the manual grant into the state file using `terraform import` or drop the grant in Snowflake and allow Terraform to re-apply it correctly. Enforce a strict "No ClickOps" policy for the DBA team.

### 3. Warehouse Misconfiguration
**Symptom:** The `PROD_BI_WH` keeps auto-suspending after 60 seconds, frustrating analysts who have to wait for it to resume.
**Root Cause:** The module default `auto_suspend = 60` was applied to the BI warehouse.
**Resolution:**
The `environments/prod/main.tf` file allows overriding module defaults. Increase `auto_suspend` to `300` (5 minutes) for the BI warehouse block and re-apply.
