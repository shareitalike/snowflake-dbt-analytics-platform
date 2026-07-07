# Operational Runbook: Disaster Recovery

## Common Production Issues

### 1. Accidental Table Drop in Production
**Symptom:** Analyst reports that `OMNIRETAIL.GOLD.FCT_SALES` is missing.
**Severity:** SEV-1 (Revenue-impacting — Power BI dashboards are broken).
**Resolution:**
```sql
UNDROP TABLE OMNIRETAIL.GOLD.FCT_SALES;
SELECT COUNT(*) FROM OMNIRETAIL.GOLD.FCT_SALES; -- Verify recovery
```
**Recovery Time:** < 30 seconds. **Data Loss:** Zero.

### 2. Corrupted Data from Bad MERGE
**Symptom:** `DIM_CUSTOMER` shows duplicate records after a faulty CDC pipeline run.
**Severity:** SEV-2.
**Resolution:**
```sql
-- Clone table to its state before the bad MERGE
CREATE TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER_RECOVERED
CLONE OMNIRETAIL.GOLD.DIM_CUSTOMER
AT (TIMESTAMP => '<timestamp_before_merge>');
-- Atomic swap
ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER RENAME TO DIM_CUSTOMER_BAD;
ALTER TABLE OMNIRETAIL.GOLD.DIM_CUSTOMER_RECOVERED RENAME TO DIM_CUSTOMER;
```
**Recovery Time:** < 2 minutes. **Data Loss:** Zero.

### 3. Terraform State Corruption
**Symptom:** `terraform plan` shows it wants to destroy and recreate all resources.
**Root Cause:** The `.tfstate` file was corrupted or accidentally deleted.
**Resolution:**
The state is stored in a versioned S3 bucket. Navigate to the S3 console, find the previous version of `terraform.tfstate`, and restore it. Then run `terraform plan` to verify the state matches reality.

### 4. Lost Secrets (Key Rotation Gone Wrong)
**Symptom:** Airflow DAGs fail with `Snowflake Authentication Error` after a key rotation.
**Root Cause:** The `rotate_snowflake_keys.py` script pushed the new private key to Secrets Manager but the `ALTER USER` command to Snowflake failed.
**Resolution:**
AWS Secrets Manager maintains version history. Restore the previous secret version, then re-run the rotation script with verbose logging to identify the Snowflake connectivity issue.
