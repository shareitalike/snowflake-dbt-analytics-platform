# Enterprise Snowflake Infrastructure as Code
## Module 02 - Design Summary

### Why Terraform for Snowflake?
Historically, DBAs managed databases using manually executed `.sql` scripts. In an enterprise environment, this leads to untraceable configuration drift and massive security vulnerabilities (e.g. accidentally granting `ACCOUNTADMIN` directly to a user).
Using the **Snowflake Terraform Provider**, we manage Warehouses, Roles, and Resource Monitors exactly like Cloud Infrastructure. All Snowflake configurations must pass through Git Pull Requests.

### Role-Based Access Control (RBAC) Hierarchy
The `snowflake/roles` module builds a rigorous hierarchy. We never assign permissions directly to a user. We create Functional Roles (`PROD_DATA_ENGINEER_ROLE`), grant database privileges to the Role, and grant the Role to the user. We also ensure that `SYSADMIN` inherits all lower-level roles so that the DBA team maintains global visibility.

### FinOps and Resource Monitors
In Snowflake, compute is billed by the second. If left unchecked, a warehouse will burn thousands of credits. The `snowflake/resource_monitors` module defines strict quotas (e.g. 100 credits/month). If the ETL warehouse hits 100%, the Resource Monitor automatically suspends it, hard-stopping all queries. By configuring this in Terraform, we guarantee that no warehouse is ever spun up without a financial safeguard attached.
