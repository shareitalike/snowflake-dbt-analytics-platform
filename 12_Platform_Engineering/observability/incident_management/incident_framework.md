# Enterprise Incident Management Framework

## Severity Matrix

| Severity | Definition | Example | Response Time | Escalation |
|----------|-----------|---------|---------------|------------|
| **SEV-1** | Revenue-impacting. Gold layer stale for >4 hours. | dbt build failed; Power BI showing yesterday's data. | 15 min | PagerDuty → On-Call Engineer → Engineering Manager |
| **SEV-2** | Pipeline degraded but recoverable. | CDC stream stale; Silver layer delayed. | 1 hour | Slack `#data-ops-critical` → On-Call Engineer |
| **SEV-3** | Non-critical. Development or QA issue. | Dev DAG failing; QA dbt test regression. | 4 hours | Slack `#data-eng-general` |
| **SEV-4** | Informational. No business impact. | Resource Monitor at 80% of budget. | Next business day | Email notification |

## Root Cause Analysis (RCA) Template

```markdown
# Incident RCA: [INCIDENT-YYYY-MM-DD-001]

## Summary
- **Date:** 
- **Duration:** 
- **Severity:** SEV-X
- **Impact:** (What business outcome was affected?)
- **Detection Method:** (Alert? User report? Scheduled check?)

## Timeline
| Time (UTC) | Event |
|-----------|-------|
| HH:MM | First anomaly detected by [monitoring system] |
| HH:MM | On-call engineer acknowledged |
| HH:MM | Root cause identified |
| HH:MM | Fix deployed |
| HH:MM | Service restored and validated |

## Root Cause
(Describe the specific technical failure. Be precise.)

## Contributing Factors
(What conditions allowed this to happen? Missing tests? Configuration gap?)

## Resolution
(What was done to restore service?)

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| Add monitoring for X | @engineer | YYYY-MM-DD | [ ] |
| Update runbook for Y | @sre | YYYY-MM-DD | [ ] |
| Add dbt test for Z | @analytics_eng | YYYY-MM-DD | [ ] |

## Lessons Learned
(What will we do differently? What worked well?)
```

## SLA / SLO / SLI Framework

| Service | SLI (Indicator) | SLO (Objective) | SLA (Agreement) |
|---------|-----------------|-----------------|-----------------|
| Gold Layer Freshness | `hours_since_last_dbt_build` | < 4 hours | 99.5% of days |
| Pipeline Success Rate | `successful_dag_runs / total_runs` | > 99% | 98% monthly |
| Query P95 Latency (BI) | `p95_query_time_seconds` | < 10 seconds | 95th percentile |
| Snowpipe Latency | `minutes_from_s3_to_bronze` | < 5 minutes | 99% of files |
