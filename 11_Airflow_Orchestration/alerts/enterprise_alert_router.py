"""
Enterprise Alert Router
Reduces "Alert Fatigue" by intelligently routing Airflow failures to the correct 
Notification Channel based on severity, tier, and domain tags.
"""
import logging
from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook
from airflow.providers.pagerduty.hooks.pagerduty import PagerdutyHook

def enterprise_alert_router(context):
    """
    Intelligently routes task failures to Slack (Warnings) or PagerDuty (Sev 1).
    Attached to the `on_failure_callback` of all DAGs.
    """
    task_instance = context.get('task_instance')
    dag = context.get('dag')
    
    dag_tags = dag.tags if dag and dag.tags else []
    
    # 1. Determine Severity
    is_tier_1 = 'tier:1' in dag_tags
    is_master = 'master' in dag_tags
    
    # 2. Extract context
    dag_id = task_instance.dag_id
    task_id = task_instance.task_id
    log_url = task_instance.log_url
    
    error_msg = f"DAG: {dag_id} | Task: {task_id} failed."

    # 3. Route to PagerDuty if Critical
    if is_tier_1 or is_master:
        logging.info("Routing alert to PagerDuty (Sev 1)...")
        try:
            pd_hook = PagerdutyHook(pagerduty_conn_id='pagerduty_default')
            pd_hook.create_event(
                routing_key="data_eng_oncall_key",
                action="trigger",
                summary=f"CRITICAL AIRFLOW FAILURE: {dag_id}",
                severity="critical",
                source="airflow-prod",
                custom_details={"task_id": task_id, "log_url": log_url}
            )
        except Exception as e:
            logging.error(f"Failed to route to PagerDuty: {e}")

    # 4. Route to Domain-Specific Slack Channel
    slack_channel = "#alerts-data-eng-general" # Fallback
    
    if 'domain:sales' in dag_tags:
        slack_channel = "#alerts-sales-data"
    elif 'domain:customer' in dag_tags:
        slack_channel = "#alerts-cx-data"
    elif 'domain:finance' in dag_tags:
        slack_channel = "#alerts-finance-data"

    logging.info(f"Routing alert to Slack channel {slack_channel}...")
    try:
        slack_hook = SlackWebhookHook(slack_webhook_conn_id='slack_api_default')
        attachments = [{"color": "#FF0000", "text": f"{error_msg}\n<{log_url}|View Logs>"}]
        slack_hook.send(attachments=attachments, channel=slack_channel)
    except Exception as e:
        logging.error(f"Failed to route to Slack: {e}")
