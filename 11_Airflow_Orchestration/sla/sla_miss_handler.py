"""
SLA Miss Handler
Triggers an escalation matrix when Data Pipelines miss their required business delivery times.
"""
import logging
from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook

def enterprise_sla_miss_escalator(dag, task_list, blocking_task_list, slas, blocking_tis):
    """
    Attached to the DAG's `sla_miss_callback`.
    Unlike a task failure (which is an engineering problem), an SLA miss is a business problem.
    """
    logging.warning(f"SLA Miss Detected for DAG: {dag.dag_id}")
    
    # Identify blocking tasks causing the delay
    blockers = ", ".join([ti.task_id for ti in blocking_tis]) if blocking_tis else "Unknown"
    
    message = (
        f"⚠️ *SLA BREACH DETECTED* ⚠️\n"
        f"*DAG:* {dag.dag_id}\n"
        f"*Blocking Tasks:* {blockers}\n"
        f"Data Freshness guarantee has been breached. Operations team has been notified."
    )
    
    # Alerting the Executive/Operations channel rather than just engineering
    try:
        slack_hook = SlackWebhookHook(slack_webhook_conn_id='slack_api_default')
        attachments = [{"color": "#FFA500", "text": message}]
        slack_hook.send(attachments=attachments, channel="#alerts-business-operations")
    except Exception as e:
        logging.error(f"Failed to escalate SLA Miss: {e}")
