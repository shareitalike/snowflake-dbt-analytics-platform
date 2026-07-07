# Client Handover Checklist

## Purpose
This checklist guarantees a smooth transition of the OmniRetail Data Platform from the consulting engineering team to the client's internal Data Engineering and Operations teams.

---

## 1. Access & Credentials
- [ ] Transfer ownership of the primary AWS Account (Root user credentials).
- [ ] Transfer ownership of the `ACCOUNTADMIN` role in Snowflake.
- [ ] Ensure all consulting team members' access (AWS IAM, Snowflake users, GitHub access) is formally revoked.
- [ ] Verify the client has access to the AWS Secrets Manager containing the Airflow Fernet key and dbt Cloud API tokens.

## 2. Code & Infrastructure
- [ ] Confirm the GitHub repository (`Project_snowflake_live`) is fully transferred and the client has Admin rights.
- [ ] Verify the Terraform remote state (S3 backend) is accessible by the client's Terraform execution role.
- [ ] Ensure all open Pull Requests are either merged or closed with detailed comments.

## 3. Operational Handoff
- [ ] Walk through the **Operations Command Center** dashboard with the client's operations lead.
- [ ] Conduct a joint execution of the **Morning Platform Health Check** (`daily_sop.md`).
- [ ] Review the **Incident Response** process and the "Five Whys" RCA template.
- [ ] Verify the client's PagerDuty/Slack routing is correctly configured in the `enterprise_alert_router`.

## 4. Disaster Recovery
- [ ] Walk through the **Snowflake Recovery Procedures** (Time Travel, UNDROP).
- [ ] Review the **RTO/RPO Matrix**.
- [ ] Schedule the first quarterly **DR Drill** with the client's engineering team.

## 5. FinOps & Cost Management
- [ ] Review the **Monthly FinOps Report** process.
- [ ] Ensure the client understands how to adjust Snowflake **Resource Monitor** budgets.
- [ ] Explain the workload isolation strategy (why `PROD_BI_WH` and `PROD_TRANSFORM_WH` are separated).

## 6. Formal Sign-Off
- **Consulting Lead:** ___________________________ Date: ____________
- **Client Sponsor:** ___________________________ Date: ____________
