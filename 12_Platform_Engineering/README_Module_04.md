# Phase 12 - Module 4: Enterprise Secrets & Configuration Management

This module completes the security and deployment foundation of the platform. We have eradicated hardcoded credentials, implemented modern OIDC authentication, and established strict Key-Pair rotations for Snowflake.

## Deliverables Checklist

- [x] **AWS IAM OIDC:** Created the Terraform module (`iam_oidc`) allowing GitHub Actions to assume an AWS role dynamically, permanently eliminating the need to store AWS Access Keys.
- [x] **GitHub Actions Pipeline:** Created `enterprise_release_pipeline.yml` utilizing the OIDC authentication and implementing TruffleHog (secret scanning) and Safety (dependency checking).
- [x] **AWS Secrets Manager & KMS:** Created Terraform modules to provision centralized secret storage, encrypted with a Customer Managed Key (CMK) for strict auditing.
- [x] **Snowflake Key Rotation:** Authored the `rotate_snowflake_keys.py` automation script for zero-downtime RSA Key Pair rotation between Snowflake and AWS Secrets Manager.
- [x] **Architecture Documentation:** Authored the [Design Summary](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_04_Design_Summary.md), [Operational Runbook](file:///F:/snowflake/Project_snow_live/Project_snowflake_live/12_Platform_Engineering/docs/Module_04_Runbook.md).md).
