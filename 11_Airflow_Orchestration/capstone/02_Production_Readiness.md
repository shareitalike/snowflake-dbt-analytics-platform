# Capstone Module: Production Readiness & Disaster Recovery

## 1. Production Readiness Checklist
Before the Airflow Orchestration platform is handed over to the business, the SRE and Data Engineering teams must sign off on the following:
- [x] **Code Quality:** GitHub Actions enforce Pylint static analysis and Black formatting on all DAGs.
- [x] **Security:** `safety check` runs in CI/CD to block known CVEs in Python packages.
- [x] **Secrets Management:** Airflow connections (`snowflake_default`, `dbt_cloud_default`) are managed via AWS Secrets Manager. No passwords exist in code.
- [x] **Alert Fatigue:** The `enterprise_alert_router` is active, ensuring only `tier:1` failures route to PagerDuty.
- [x] **SLA Enforcement:** The `enterprise_sla_miss_escalator` is active, distinguishing business delays from engineering failures.
- [x] **Scalability:** Deferrable operators and `mode='reschedule'` sensors are used globally to prevent worker starvation.

## 2. Disaster Recovery Strategy

### RTO (Recovery Time Objective): 15 Minutes
### RPO (Recovery Point Objective): 0 Minutes (No Data Loss)

Because Airflow is purely a *Control Plane*, it holds no customer data. Our DR strategy relies on Infrastructure-as-Code (Terraform) and CI/CD (GitHub Actions).

**Scenario: Entire AWS `us-east-1` Region Goes Down**
1. Terraform is executed against `us-west-2` to stand up a new MWAA cluster (5 minutes).
2. The CI/CD pipeline is re-triggered to sync the `dags/` folder to the new S3 bucket in `us-west-2` (2 minutes).
3. Airflow automatically pulls its metadata configuration from the replicated AWS RDS Postgres cluster (3 minutes).
4. The platform resumes execution exactly where it left off.

## 3. UAT (User Acceptance Testing) Checklist
- [x] Finance team confirms they receive Slack notifications only for the `finance` domain.
- [x] Operations team confirms they receive notifications for SLA breaches.
- [x] Data Engineering confirms they can deploy a new pipeline simply by modifying `domain_config.yaml` (Metadata Registry) without writing Python code.
