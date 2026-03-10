# Interview Notes: AWS Landing Zone Architecture

## "Why did you use SQS/SNS for Snowpipe instead of standard S3 Event Notifications?"
**Answer:** While Snowpipe supports direct S3 event notifications, using an SNS topic fanned out to an SQS queue is the enterprise standard. It decouples the publisher (S3) from the consumer (Snowpipe), allowing us to:
1. Route the same S3 event to multiple consumers in the future (e.g., triggering a Lambda function for scanning malicious files, *and* triggering Snowpipe).
2. Attach a Dead Letter Queue (DLQ) to the SQS queue. If Snowflake is down or the ingestion pipe is paused, the events aren't lost—they queue up and can be re-driven, guaranteeing zero data loss.

## "How did you secure the connection between AWS and Snowflake?"
**Answer:** We eliminated static Access Keys entirely. We implemented a cross-account IAM Role using Snowflake's provided `STORAGE_AWS_IAM_USER_ARN`. More importantly, to prevent the "Confused Deputy" vulnerability, we enforced an `sts:ExternalId` condition in the trust policy, ensuring only our specific Snowflake account can assume the role. Furthermore, the role's policy strictly limits `s3:GetObject` and `s3:ListBucket` access to only the `landing` and `raw` buckets, ignoring the rest of the data lake.

## "How did you optimize S3 costs for the Data Lake?"
**Answer:** We implemented Terraform lifecycle policies to automatically transition data. For the `raw` bucket, data transitions to Standard-Infrequent Access (Standard-IA) after 60 days. For the `archive` bucket, we transition data to Amazon Glacier after 30 days and set it to expire entirely after 365 days.

## "Why structure Terraform with modules instead of a single main.tf?"
**Answer:** Modularization separates the "definition" of infrastructure from the "instantiation" of it. By abstracting S3, IAM, and Security into `modules/`, we can deploy identical infrastructure to our `dev`, `qa`, and `prod` environments merely by passing different variable maps, ensuring environment parity and adhering to the DRY principle.
