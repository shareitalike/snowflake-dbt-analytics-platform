# On-Call Support Playbook

## Production Support Model
We operate a Follow-the-Sun / Tiered support model.
- **Tier 1 (L1):** Automated Alerting & Operations Command Center.
- **Tier 2 (L2):** On-Call Data Engineer (rotates weekly). Handles initial triage, DAG restarts, known runbook execution.
- **Tier 3 (L3):** Principal Architects / SREs. Engaged for complex Snowflake performance tuning, Terraform state corruption, or architectural failures.

## Escalation Matrix

| Severity | Definition | Initial Contact | L2 Response | Escalation to L3 (If unresolved) |
|----------|------------|-----------------|-------------|----------------------------------|
| **SEV-1** | Business halted (e.g., Gold data missing) | PagerDuty | 15 mins | 30 mins |
| **SEV-2** | Critical pipeline degraded | Slack `@oncall-data` | 1 hour | 4 hours |
| **SEV-3** | Non-critical / Dev failure | Slack `#data-eng` | 4 hours | N/A |
| **SEV-4** | Information / Warning | Email | Next Biz Day| N/A |

## Communication Templates

### Initial Acknowledgement (SEV-1/2)
**Channel:** `#incident-management`
> "🚨 **[INCIDENT]** I am investigating the SEV-1 alert regarding [Issue]. I have acknowledged the PagerDuty alarm. Next update in 15 minutes."

### Update (Every 30 mins during SEV-1)
> "⚠️ **[UPDATE]** We have identified the issue as [Root Cause]. We are currently executing [Fix Action]. ETA to resolution is [Time]. Business Impact: [Impact]."

### Resolution
> "✅ **[RESOLVED]** The issue has been mitigated. Pipelines have caught up. Root cause was [Cause]. An RCA meeting will be scheduled within 48 hours."
