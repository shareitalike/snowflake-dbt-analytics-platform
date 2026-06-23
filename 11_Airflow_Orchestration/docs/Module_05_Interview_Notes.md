# Interview Notes: Sensors & Event-Driven Architecture

## Q: When do you use Sensors in Airflow?
**A:** "We use sensors to transition from time-based scheduling to event-driven orchestration. Instead of guessing that an upstream AWS S3 file will arrive by 3:00 AM, we schedule the DAG at midnight but put an `S3KeySensor` as the first task. The DAG wakes up, pokes S3, and goes back to sleep until the file actually lands. It guarantees we never process partial data and never waste time waiting."

## Q: How do you avoid Sensor resource waste? (Crucial Question)
**A:** "In legacy Airflow, Junior engineers often used `mode='poke'`. If an S3 file is delayed by 5 hours, the worker thread sits idle for 5 hours, blocking other tasks (Sensor Starvation). We optimize this in two ways:
1. **Reschedule Mode:** We enforce `mode='reschedule'` for basic sensors. It tells the sensor: 'Check S3. If the file isn't there, release the worker back to the cluster pool, and schedule yourself to check again in 5 minutes.'
2. **Deferrable Operators (Airflow 2.2+):** For heavy external API polling (like waiting 2 hours for a dbt Cloud Job or Snowpark ML model to finish), we use Deferrable Sensors. Instead of waking up a Celery worker every 5 minutes to check the status, the Sensor completely passes the workload to the Airflow **Triggerer** component. The Triggerer uses highly efficient Python `asyncio` loops, allowing a single node to monitor thousands of dbt jobs simultaneously with almost zero CPU overhead."

## Q: How do you handle alerting across hundreds of DAGs?
**A:** "We don't want engineers writing custom Slack integration code in every DAG. I built an `enterprise_callbacks.py` module. We attach `on_failure_callback=enterprise_failure_callback` to the `default_args` dictionary at the top of the DAG. If any task fails, Airflow automatically intercepts the stack trace, formats it into a Slack Webhook payload, and alerts the Data Engineering channel with a direct link to the logs."

## Enterprise Best Practices Demonstrated
1. **Reschedule Mode:** Absolute necessity for high-scale Airflow deployments.
2. **Centralized Callbacks:** Enforcing a standardized observability framework without duplicating code.
