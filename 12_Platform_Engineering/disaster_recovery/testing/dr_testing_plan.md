# Enterprise Disaster Recovery Testing Plan
## Quarterly DR Drill Procedures

### Purpose
Disaster Recovery plans are worthless if untested. We execute the following DR drills quarterly to validate our RTO/RPO targets and ensure the engineering team is proficient in recovery procedures.

---

## DR Drill 1: Table Recovery (Time Travel)
**Objective:** Validate that a dropped or corrupted table can be recovered within the RTO target.
**RTO Target:** < 5 minutes
**Frequency:** Quarterly

### Procedure
1. Create a test table in `OMNIRETAIL_QA`: `CREATE TABLE QA_DR_TEST AS SELECT * FROM OMNIRETAIL.GOLD.FCT_SALES LIMIT 10000;`
2. Record the current timestamp: `SELECT CURRENT_TIMESTAMP();`
3. Drop the table: `DROP TABLE OMNIRETAIL_QA.GOLD.QA_DR_TEST;`
4. Start timer.
5. Execute recovery: `UNDROP TABLE OMNIRETAIL_QA.GOLD.QA_DR_TEST;`
6. Validate: `SELECT COUNT(*) FROM OMNIRETAIL_QA.GOLD.QA_DR_TEST;` — Must equal 10,000.
7. Stop timer. Record recovery duration.

### Pass Criteria
- Recovery completed in < 5 minutes.
- Row count matches pre-drop count exactly.
- No data corruption detected.

---

## DR Drill 2: Pipeline Recovery (Airflow + dbt)
**Objective:** Validate that a completely failed pipeline can be restarted and produces correct results.
**RTO Target:** < 30 minutes
**Frequency:** Quarterly

### Procedure
1. Deliberately pause the `enterprise_master_orchestrator_dag` in Airflow.
2. Clear the task instances for the last successful run.
3. Start timer.
4. Unpause the DAG and trigger a manual run.
5. Monitor: dbt Cloud build must complete successfully.
6. Validate: Gold layer row counts must match expected values.
7. Stop timer. Record recovery duration.

### Pass Criteria
- DAG resumed without manual intervention beyond the initial trigger.
- dbt build completed with 0 test failures.
- Gold layer freshness returned to `🟢 FRESH` status.

---

## DR Drill 3: Full Environment Recovery (Terraform)
**Objective:** Validate that the entire platform infrastructure can be rebuilt from scratch using Terraform.
**RTO Target:** < 60 minutes
**Frequency:** Semi-annually

### Procedure
1. Document the current state of the QA environment.
2. Destroy the QA Terraform state: `terraform destroy -auto-approve` (QA only!).
3. Start timer.
4. Re-initialize: `terraform init && terraform apply -auto-approve`.
5. Re-deploy Airflow DAGs: `aws s3 sync dags/ s3://omniretail-airflow-qa-bucket/dags/`.
6. Run smoke tests: `pytest tests/smoke_tests.py`.
7. Validate: All Snowflake warehouses, databases, roles, and connections exist.
8. Stop timer. Record recovery duration.

### Pass Criteria
- Full environment rebuilt in < 60 minutes.
- All smoke tests pass.
- All Airflow connections functional.

---

## RTO / RPO Matrix

| Component | RPO | RTO | Recovery Method |
|-----------|-----|-----|----------------|
| Snowflake Tables (Bronze) | 0 min | 30 sec | UNDROP / Time Travel (90 days) |
| Snowflake Tables (Gold) | 0 min | 18 min | dbt Cloud full rebuild |
| Airflow Metadata | 24 hours | 15 min | RDS automated backup + MWAA restart |
| Airflow DAGs | 0 min | 2 min | GitHub → S3 sync (CI/CD pipeline) |
| Terraform State | 0 min | 5 min | S3 versioned backend recovery |
| AWS Secrets | 0 min | 10 min | Secrets Manager versioning |
| dbt Cloud Project | 0 min | 0 min | Git repository (source of truth) |
| Power BI Dashboards | N/A | 30 min | Re-point to recovered Snowflake |
