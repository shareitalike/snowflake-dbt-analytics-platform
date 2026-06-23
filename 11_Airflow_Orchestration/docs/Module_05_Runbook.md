# Operational Runbook: Sensors & Callbacks

## Common Production Issues

### 1. Sensor Starvation (Worker Deadlock)
**Symptom:** No DAGs are running. The Airflow UI shows dozens of tasks in `queued` state, but none are moving to `running`. The active running tasks are all Sensors.
**Root Cause:** A Data Engineer deployed a Sensor using `mode='poke'` with a 10-hour timeout. The sensors consumed 100% of the available Celery worker slots, preventing any actual work from executing.
**Resolution:**
Terminate the running sensors. Enforce code reviews to ensure all long-running sensors use `mode='reschedule'`.

### 2. Missing Files (Sensor Timeout)
**Symptom:** `S3KeySensor` fails after 1 hour, triggering the `enterprise_failure_callback`.
**Root Cause:** The upstream partner (e.g., Salesforce export) failed to deliver the daily file to the S3 bucket.
**Resolution:**
The failure callback will automatically alert the Slack `#alerts-data-eng` channel. The on-call engineer must contact the upstream vendor. Once the file is manually dropped into S3, the engineer can clear the Sensor task in the Airflow UI, and the event-driven DAG will automatically resume.

### 3. False Triggers & Duplicate Events
**Symptom:** A pipeline runs twice in one hour.
**Root Cause:** The upstream system dropped a partial file, triggering the `S3KeySensor`, and then dropped the complete file 10 minutes later.
**Resolution:**
Ensure upstream systems write to a temporary prefix (e.g., `/tmp/file.json`) and only `MV` (move) the file to the target prefix when the write is complete. The Sensor should only listen to the target prefix. Additionally, ensure the downstream `SnowflakeOperator` is idempotent (using `MERGE` instead of `INSERT`).
