"""
Enterprise Callbacks
Centralized Slack alerting system for DAG lifecycle events (Success, Failure, SLA Miss).
These are attached to the `default_args` of a DAG to automate alerting.
"""
import logging
from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook

def _send_slack_alert(context, message: str, color: str):
    """Helper method to format and send Slack alerts."""
    try:
        hook = SlackWebhookHook(slack_webhook_conn_id='slack_api_default')
        dag_id = context.get('task_instance').dag_id
        task_id = context.get('task_instance').task_id
        execution_date = context.get('execution_date')
        log_url = context.get('task_instance').log_url

        formatted_message = (
            f"*{message}*\n"
            f"*DAG:* {dag_id}\n"
            f"*Task:* {task_id}\n"
            f"*Execution Date:* {execution_date}\n"
            f"<{log_url}|View Logs>"
        )

        attachments = [{"color": color, "text": formatted_message}]
        hook.send(attachments=attachments)
    except Exception as e:
        logging.error(f"Failed to send Slack alert: {str(e)}")

def enterprise_failure_callback(context):
    """Triggered when an Airflow Task throws an Exception."""
    logging.error("Executing Enterprise Failure Callback...")
    _send_slack_alert(context, message="🚨 AIRFLOW TASK FAILED 🚨", color="#FF0000")

def enterprise_success_callback(context):
    """Optional: Triggered when a critical DAG completes successfully."""
    logging.info("Executing Enterprise Success Callback...")
    _send_slack_alert(context, message="✅ AIRFLOW TASK SUCCEEDED ✅", color="#00FF00")

def enterprise_sla_miss_callback(dag, task_list, blocking_task_list, slas, blocking_tis):
    """Triggered when a DAG exceeds its defined SLA time limit."""
    logging.warning("Executing Enterprise SLA Miss Callback...")
    # Requires a custom implementation since context is passed differently for SLAs
    try:
        hook = SlackWebhookHook(slack_webhook_conn_id='slack_api_default')
        formatted_message = f"⚠️ *SLA MISS DETECTED* ⚠️\n*DAG:* {dag.dag_id}\nThe SLA threshold was breached."
        attachments = [{"color": "#FFA500", "text": formatted_message}]
        hook.send(attachments=attachments)
    except Exception as e:
        logging.error(f"Failed to send Slack SLA alert: {str(e)}")
