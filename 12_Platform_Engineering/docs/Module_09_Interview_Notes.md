# Interview Notes: Enterprise Operations & SRE

## Q: How do you support production pipelines?
**A:** "I believe in an SRE approach, which means prioritizing proactive observability over reactive ticketing. I built an Operations Command Center that aggregates Snowflake, Airflow, and dbt metrics. I also enforce a strict Daily SOP for the on-call engineer to review automated health checks. If an issue occurs, we have an Escalation Matrix mapping severity levels to specific response times and communication templates."

## Q: How do you perform Root Cause Analysis?
**A:** "For any SEV-1 or SEV-2 incident, I require an RCA document within 48 hours. I use the 'Five Whys' technique to drill past the technical error and find the systemic process failure. For example, if a query timed out, the first 'why' is a stuck warehouse. But the fifth 'why' might reveal that a manual role grant bypassed our Terraform CI/CD pipeline. The output of the RCA is always a Corrective and Preventive Action (CAPA) assigned as a Jira ticket."

## Q: How do you handle emergency changes (hotfixes)?
**A:** "Manual changes in production are the fastest way to corrupt state. Even in an emergency, we do not log into the Snowflake UI to execute DDL. We create a hotfix branch, commit the fix, and let the GitHub Actions pipeline deploy it. This guarantees that our Terraform state and Git repository remain the single source of truth, and allows us to use `git revert` if the hotfix itself causes issues."

## Q: What are your regular maintenance tasks?
**A:** "Weekly, I review the FinOps dashboard to identify any queries scanning >90% of partitions, which usually indicates we need a clustering key. I also review staging databases to drop unused transient tables. Monthly, I review the `GRANTS_TO_USERS` view in Snowflake to ensure no one bypassed Terraform for access control, and I conduct a full DR drill to validate our RTO/RPO metrics."
