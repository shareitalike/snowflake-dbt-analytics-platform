# AWS Infrastructure Validation Checklist

Before marking the AWS Landing Zone deployment as "Production Ready", the DevOps Engineer must validate the following configurations in the AWS Console.

## 1. S3 Data Lake
- [ ] Verify 7 buckets exist (landing, raw, archive, quarantine, analytics, logs, backup).
- [ ] **Security:** Confirm "Block all public access" is turned ON for all buckets.
- [ ] **Encryption:** Confirm default encryption is set to AWS KMS (not Amazon S3 managed keys).
- [ ] **Versioning:** Confirm bucket versioning is ENABLED on all buckets.
- [ ] **Lifecycle:** Verify the `archive` bucket has a rule transitioning objects to GLACIER after 30 days.

## 2. IAM & Security
- [ ] **Snowflake Role:** Review the Trust Relationships for `${project}-${environment}-snowflake-s3-role`. Confirm the `sts:ExternalId` condition exactly matches the external ID provided by the Snowflake account.
- [ ] **Snowflake Policies:** Verify the attached policy only grants `s3:GetObject` and `s3:ListBucket` strictly to the `landing` and `raw` buckets.
- [ ] **CI/CD Role:** Verify the GitHub Actions role uses OIDC Federation (`token.actions.githubusercontent.com`).

## 3. SQS & SNS (Snowpipe)
- [ ] Upload a test file to the `landing` bucket.
- [ ] Check the `${project}-${environment}-snowpipe-queue` SQS queue to confirm a message was received.
- [ ] Verify the SQS queue has a Dead Letter Queue (DLQ) configured with `maxReceiveCount` = 3.

## 4. Enterprise Security Baselines
- [ ] **CloudTrail:** Verify the multi-region trail is active and logging to the designated S3 bucket.
- [ ] **GuardDuty:** Confirm the detector is enabled in the current region.
- [ ] **AWS Config:** Confirm the Config Recorder is active and tracking all supported resources.
