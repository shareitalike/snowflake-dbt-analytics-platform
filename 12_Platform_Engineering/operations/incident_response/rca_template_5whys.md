# Incident Response & Root Cause Analysis (RCA)

## Incident Response Process

1. **Detect & Triage:** Alert fires (PagerDuty, Slack). On-call engineer acknowledges within SLA.
2. **Contain & Mitigate:** Stop the bleeding. Suspend failing DAGs, scale up warehouse, or disable broken upstream ingestion.
3. **Resolve:** Implement the fix (e.g., Git revert, backfill data, UNDROP table).
4. **Post-Mortem (RCA):** Conducted within 48 hours for any SEV-1 or SEV-2 incident.

---

## Root Cause Analysis (RCA) Template

**Incident ID:** INC-2025-07-[XX]
**Date:** YYYY-MM-DD
**Severity:** [SEV-1 / SEV-2]
**Lead Investigator:** @[Name]

### 1. Executive Summary
*Brief description of what happened, business impact, and resolution.*

### 2. Timeline
- **08:00 UTC:** Alert triggered by Operations Command Center.
- **08:15 UTC:** Acknowledged by on-call.
- **08:30 UTC:** Root cause identified.
- **09:00 UTC:** Fix deployed. Service restored.

### 3. The "Five Whys" (Root Cause Identification)
*Ask "Why?" until you reach the systemic process failure, not just the technical error.*

1. **Why did the Power BI dashboard fail to load?** 
   Because the query timed out after 10 minutes.
2. **Why did the query time out?** 
   Because `PROD_BI_WH` was stuck in a massive queue.
3. **Why was the warehouse queued?** 
   Because a Data Scientist accidentally ran a cross-join on the BI warehouse instead of the Ad-Hoc warehouse.
4. **Why was the Data Scientist able to use the BI warehouse?** 
   Because the `PROD_DATA_SCIENTIST_ROLE` was mistakenly granted `USAGE` on `PROD_BI_WH`.
5. **Why was the role misconfigured?**
   Because a manual `GRANT` was run in production, bypassing Terraform access controls.

**Root Cause:** Manual, out-of-band role provisioning bypassed Terraform state.

### 4. Corrective and Preventive Actions (CAPA)

| Action Item | Type | Owner | Status |
|-------------|------|-------|--------|
| Revoke `USAGE` on `PROD_BI_WH` from Data Scientists | Corrective | @sre | Done |
| Enforce Terraform state via CI/CD (remove manual `GRANT` privileges from users) | Preventive | @architect | In Progress |
| Add Airflow check to monitor unauthorized grants in `ACCOUNT_USAGE` | Preventive | @data_engineer | Planned |

### 5. Lessons Learned
- We need stricter Terraform drift detection to catch manual grants quickly.
- The 10-minute statement timeout on the BI warehouse worked successfully to prevent infinite credit burn, even though it caused a BI timeout.
