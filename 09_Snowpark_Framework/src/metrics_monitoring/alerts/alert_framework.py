import logging
from typing import Dict, Any

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class AlertFramework:
    """
    Routes operational alerts to the correct channels based on severity.
    Integrates with Snowflake External Network Access to ping webhooks.
    """
    SEVERITY_LEVELS = ["INFO", "WARNING", "CRITICAL"]

    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def trigger_alert(self, title: str, message: str, severity: str, context: Dict[str, Any] = None):
        """
        Routes the alert. 
        CRITICAL -> PagerDuty/OpsGenie
        WARNING -> Slack/Teams
        INFO -> Dashboard Logging only
        """
        if severity not in self.SEVERITY_LEVELS:
            severity = "INFO"
            
        log_payload = {
            "alert_title": title,
            "severity": severity,
            "context": context or {}
        }

        if severity == "CRITICAL":
            self.logger.error(f"CRITICAL ALERT: {message}", extra=log_payload)
            self._send_pagerduty(title, message, context)
            
        elif severity == "WARNING":
            self.logger.warning(f"WARNING ALERT: {message}", extra=log_payload)
            self._send_slack(title, message, context)
            
        else:
            self.logger.info(f"INFO ALERT: {message}", extra=log_payload)

    def _send_pagerduty(self, title: str, message: str, context: dict):
        """Mock external network call to PagerDuty API."""
        # requests.post(pagerduty_url, json=...)
        pass

    def _send_slack(self, title: str, message: str, context: dict):
        """Mock external network call to Slack Webhook."""
        # requests.post(slack_webhook, json=...)
        pass
