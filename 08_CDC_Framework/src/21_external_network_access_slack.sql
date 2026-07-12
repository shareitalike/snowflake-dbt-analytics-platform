/* ==============================================================================
 * FILE: 21_external_network_access_slack.sql
 * PHASE: 08 - CDC Framework (Observability Layer)
 * 
 * EXPLANATION: Configures Snowflake External Network Access (ENA) to allow secure 
 *              outbound HTTP requests to the Slack API.
 * 
 * DESIGN DECISIONS: 
 *   - Uses a Snowflake SECRET to securely hide the Webhook URL from the codebase.
 *   - Leverages a Python Stored Procedure via Snowpark to read the TB_ALERT_QUEUE, 
 *     dispatch the Slack message, and mark the alert as "Sent".
 * 
 * WHY ENA?: 
 *   - Decouples pipeline execution from external API calls. 
 *   - Eliminates the need to maintain external AWS Lambda functions or API Gateways 
 *     just to route operational alerts.
 *   - Keeps all orchestration and alerting native within Snowflake's security perimeter.
 * ============================================================================== */

USE ROLE ACCOUNTADMIN;
USE DATABASE DB_PROD_METADATA;
USE SCHEMA SC_META_OBSERVABILITY;

-- ------------------------------------------------------------------------------
-- 1. CREATE NETWORK RULE
-- ------------------------------------------------------------------------------
-- Whitelists the Slack Webhook domain. Snowflake strictly blocks all outbound traffic
-- except to destinations explicitly allowed in a network rule.
CREATE OR REPLACE NETWORK RULE NR_SLACK_WEBHOOK
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hooks.slack.com');

-- ------------------------------------------------------------------------------
-- 2. CREATE SECURE SECRET
-- ------------------------------------------------------------------------------
-- Stores the Slack Webhook URL securely so it is never hardcoded in scripts.
-- Note: Replace the SECRET_STRING with your actual Slack webhook URL.
CREATE OR REPLACE SECRET SEC_SLACK_WEBHOOK
  TYPE = GENERIC_STRING
  SECRET_STRING = '<YOUR_SLACK_WEBHOOK_URL_HERE>';

-- ------------------------------------------------------------------------------
-- 3. CREATE EXTERNAL ACCESS INTEGRATION
-- ------------------------------------------------------------------------------
-- Binds the Network Rule and the Secret together into a single Integration object.
-- This integration is then explicitly granted to the dispatcher Stored Procedure.
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION EAI_SLACK_ALERTS
  ALLOWED_NETWORK_RULES = (NR_SLACK_WEBHOOK)
  ALLOWED_AUTHENTICATION_SECRETS = (SEC_SLACK_WEBHOOK)
  ENABLED = TRUE;

-- ------------------------------------------------------------------------------
-- 4. CREATE DISPATCHER STORED PROCEDURE (PYTHON)
-- ------------------------------------------------------------------------------
-- This procedure utilizes the ENA integration to send messages. It is designed to
-- run on a scheduled Snowflake task (e.g., every 1 minute), scan the Alert Queue, 
-- post the message to Slack, and mark it as successfully dispatched.
CREATE OR REPLACE PROCEDURE SP_DISPATCH_SLACK_ALERTS()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.10
PACKAGES = ('snowflake-snowpark-python', 'requests')
EXTERNAL_ACCESS_INTEGRATIONS = (EAI_SLACK_ALERTS)
SECRETS = ('slack_secret' = SEC_SLACK_WEBHOOK)
HANDLER = 'dispatch_alerts'
AS
$$
import _snowflake
import requests
import json
from snowflake.snowpark import Session

def dispatch_alerts(session: Session):
    # 1. Retrieve the Webhook URL securely from the Snowflake Secret
    slack_url = _snowflake.get_generic_secret_string('slack_secret')
    
    # 2. Query the TB_ALERT_QUEUE for pending, unsent alerts
    query = """
        SELECT Alert_ID, Alert_Type, Severity, Pipeline_ID, Alert_Message
        FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE
        WHERE Is_Resolved = FALSE
          AND Is_Dispatched = FALSE
        ORDER BY Created_At ASC
        LIMIT 20; -- Process in small, controlled batches
    """
    
    try:
        df = session.sql(query).collect()
    except Exception as e:
        return f"Error querying alert queue: {str(e)}"
        
    alerts_sent = 0
    
    for row in df:
        alert_id = row['ALERT_ID']
        
        # Format the Slack message block
        alert_text = f"🚨 *{row['SEVERITY']} ALERT: {row['ALERT_TYPE']}* 🚨\n" \
                     f"*Pipeline:* `{row['PIPELINE_ID']}`\n" \
                     f"*Details:* {row['ALERT_MESSAGE']}\n" \
                     f"👉 _Check the Streamlit CDC Monitor for details._"
        
        slack_payload = {"text": alert_text}
        
        # 3. Execute the Outbound HTTP POST request to Slack
        try:
            response = requests.post(slack_url, json=slack_payload, timeout=10)
            response.raise_for_status()
            
            # 4. If successful, update the queue to mark as Dispatched
            update_sql = f"UPDATE DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_ALERT_QUEUE SET Is_Dispatched = TRUE WHERE Alert_ID = '{alert_id}'"
            session.sql(update_sql).collect()
            
            alerts_sent += 1
            
        except requests.exceptions.RequestException as e:
            # If Slack API fails, log the error but continue processing other alerts
            # A more robust system would implement a retry-count here.
            pass
            
    return f"Execution Complete. Successfully dispatched {alerts_sent} alerts to Slack."
$$;
