# Interview Notes: Terraform Platform Engineering

## Q: Why use Terraform instead of Snowflake UI or AWS Console?
**A:** "ClickOps (using the UI) is an anti-pattern. If you rely on the UI, you cannot audit who made a change, you cannot easily roll back, and you cannot replicate Production into QA without days of manual work. Terraform provides Infrastructure as Code. It makes infrastructure versionable, reviewable via PRs, and instantly deployable. It's the foundation of Disaster Recovery."

## Q: How do you manage different environments in Terraform?
**A:** "I use a modular structure. I build generic, reusable modules for things like 'Snowflake Warehouse' or 'AWS S3 Bucket'. Then, I have environment-specific directories (`environments/dev`, `environments/prod`). The `prod` environment simply imports the modules but passes production-scale variables (e.g., `warehouse_size = "LARGE"`). This guarantees architectural parity between Dev and Prod."

## Q: How do you manage Terraform state in an enterprise?
**A:** "Local state files are a security and operational nightmare. I configure Terraform with a remote S3 backend. This stores the `.tfstate` file in a centralized, KMS-encrypted S3 bucket. More importantly, I attach a DynamoDB table for State Locking. If the CI/CD pipeline is deploying changes, DynamoDB locks the state so no other engineer can accidentally deploy conflicting changes simultaneously."

## Q: How does Terraform enforce FinOps?
**A:** "When I design the Snowflake modules, I hardcode safeguards. For instance, in my Snowflake Warehouse module, I enforce the `statement_timeout_in_seconds` parameter. A developer can request an XL warehouse, but because they have to use my module, Terraform automatically guarantees that no query runs for more than 2 hours. This prevents runaway compute bills."
