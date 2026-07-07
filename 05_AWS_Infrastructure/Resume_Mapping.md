# Resume Mapping: AWS Landing Zone Implementation

By completing this module, you can confidently add the following bullet points to your resume under the **OmniRetail Group** (or relevant project) experience section:

## Senior Cloud / Data Engineer Bullets:
* Designed and deployed a production-grade AWS Data Lake Landing Zone using modular **Terraform**, provisioning highly secure S3 architectures with KMS encryption, versioning, and cost-optimizing Glacier lifecycle policies.
* Architected a zero-data-loss **Snowpipe CDC ingestion framework** utilizing AWS S3 Event Notifications, SNS fan-out topics, and SQS Dead Letter Queues (DLQ) for highly resilient micro-batch processing.
* Enforced strict Zero-Trust security postures by establishing cross-account AWS IAM Roles for Snowflake Storage Integrations, completely eliminating static credential risks via `sts:ExternalId` trust conditions.
* Established enterprise compliance baselines across the AWS environment by codifying **AWS CloudTrail**, **GuardDuty**, and **AWS Config** rules via Infrastructure as Code.

## Principal Architect Bullets:
* Led the enterprise Cloud Architecture strategy, delivering a DRY, multi-environment Terraform repository structure that guaranteed 100% environment parity across Development, QA, and Production data platforms.
* Designed the end-to-end event-driven architecture connecting AWS (S3/SNS/SQS) with Snowflake, reducing data ingestion latency from 24-hour batch cycles to under 15 minutes.
