# Interview Notes: Snowflake Infrastructure as Code

## Q: How do you manage Snowflake infrastructure? Do you use SQL scripts?
**A:** "In my enterprise projects, I treat Snowflake exactly like AWS. I use Terraform. Using manual SQL scripts or flyway migrations for *infrastructure* (Roles, Warehouses, Resource Monitors) causes state drift. By using the Snowflake Terraform Provider, every role, grant, and warehouse requires a Pull Request. This enforces strict GitOps and allows us to tear down and rebuild an entire Snowflake environment in minutes during Disaster Recovery."

## Q: How do you prevent runaway compute costs in Snowflake?
**A:** "FinOps is embedded into my IaC. Developers cannot create a warehouse using the Snowflake UI; they must use my Terraform module. My module hardcodes the `statement_timeout_in_seconds` variable. Additionally, I deploy `snowflake_resource_monitor` resources via Terraform that track credit quotas and automatically suspend the warehouse if it hits 100% of its budget. By forcing infrastructure through Terraform, I force financial compliance."

## Q: How do you avoid configuration drift?
**A:** "If a DBA manually creates a role or alters a warehouse in the Snowflake UI, Terraform will detect that drift during the next CI/CD pipeline run. `terraform plan` will show that the manual UI changes deviate from the `.tfstate` file, and `terraform apply` will automatically overwrite and revert those manual changes. It forces the engineering team to adopt a 'Code First' culture."

## Enterprise Best Practices Demonstrated
1. **Infrastructure as Code (IaC):** Treating data platforms (Snowflake) with the exact same rigor as cloud infrastructure (AWS).
2. **RBAC via Terraform:** Creating clear functional roles and hierarchies programmatically.
