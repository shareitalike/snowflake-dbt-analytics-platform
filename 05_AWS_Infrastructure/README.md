# AWS Infrastructure: Landing Zone Deployment Guide

## Overview
This module contains the enterprise-grade Terraform codebase for provisioning the OmniRetail Group AWS Landing Zone. It implements strict IAM policies, S3 data lakes with lifecycle and encryption rules, SQS/SNS event routing for Snowflake Snowpipe, and security baselines via CloudTrail, GuardDuty, and AWS Config.

## Repository Structure
```text
05_AWS_Infrastructure/
├── modules/
│   ├── s3/        # Buckets, KMS Encryption, Lifecycle
│   ├── iam/       # Snowflake Integration, Airflow, CI/CD Roles
│   ├── sqs_sns/   # Event Notifications for Snowpipe CDC
│   └── security/  # CloudTrail, Config, GuardDuty
├── environments/
│   ├── dev/
│   ├── qa/
│   └── prod/      # Production environment definition
```

## Deployment Order & Prerequisites
1. **AWS Authentication:** Ensure you are authenticated with Administrator credentials to bootstrap the environment.
2. **KMS Key Creation:** A symmetric KMS key must be created manually or in a separate bootstrap script to provide the `kms_key_arn` for S3 encryption.
3. **Snowflake Integration Setup (Part 1):** Execute `CREATE STORAGE INTEGRATION` in Snowflake first to generate the `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID`.
4. **Terraform Execution:**
   ```bash
   cd environments/prod
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```
5. **Snowflake Integration Setup (Part 2):** After Terraform applies, take the generated `snowflake_storage_role` ARN and update the Snowflake Storage Integration.

## Best Practices Enforced
* **State Management:** Remote state is stored in S3 with DynamoDB locking (defined in `backend.tf`).
* **KMS Encryption:** Enforced `aws:kms` server-side encryption across all S3 buckets by default.
* **Least Privilege:** The Snowflake IAM role only has access to specific S3 buckets via explicit ARN definitions; it uses `sts:ExternalId` to prevent the Confused Deputy problem.
* **Cost Optimization:** S3 lifecycle rules automatically transition raw/archive data to Standard-IA and Glacier.
* **Event-Driven Ingestion:** Snowpipe relies on SQS/SNS rather than expensive polling.

## Next Steps
Review the `Validation_Checklist.md` to verify the deployment before handing the environment over to the Data Engineering team.
