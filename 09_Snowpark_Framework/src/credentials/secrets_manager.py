import os
import json
import logging
from typing import Dict, Any

from src.utilities.exceptions import SecretsRetrievalError

logger = logging.getLogger(__name__)

class SecretsManager:
    """
    Retrieves credentials dynamically to avoid hardcoding secrets.
    Supports local .env loading and AWS Secrets Manager.
    """

    @staticmethod
    def get_credentials(strategy: str, secret_name: str, region: str = "us-east-1") -> Dict[str, Any]:
        """
        Retrieves the Snowflake credentials dictionary based on the provided strategy.
        """
        if strategy.lower() == "env":
            logger.info("Fetching secrets from environment variables (local/dev mode).")
            user = os.getenv("SNOWFLAKE_USER")
            password = os.getenv("SNOWFLAKE_PASSWORD")
            
            if not user or not password:
                raise SecretsRetrievalError("SNOWFLAKE_USER or SNOWFLAKE_PASSWORD env vars are missing.")
                
            return {
                "user": user,
                "password": password
            }
            
        elif strategy.lower() == "aws_secrets_manager":
            logger.info(f"Fetching secrets from AWS Secrets Manager: {secret_name}")
            try:
                import boto3
                from botocore.exceptions import ClientError
            except ImportError:
                raise SecretsRetrievalError("boto3 is not installed but aws_secrets_manager strategy was requested.")

            if not secret_name:
                raise SecretsRetrievalError("secret_name must be provided for aws_secrets_manager strategy.")

            session = boto3.session.Session()
            client = session.client(service_name='secretsmanager', region_name=region)

            try:
                get_secret_value_response = client.get_secret_value(SecretId=secret_name)
            except ClientError as e:
                logger.error(f"AWS Secrets Manager Error: {str(e)}")
                raise SecretsRetrievalError(f"Failed to fetch secret '{secret_name}': {str(e)}")

            if 'SecretString' in get_secret_value_response:
                secret = get_secret_value_response['SecretString']
                try:
                    secret_dict = json.loads(secret)
                    if "user" not in secret_dict or "password" not in secret_dict:
                        raise SecretsRetrievalError("Secret JSON must contain 'user' and 'password' keys.")
                    return secret_dict
                except json.JSONDecodeError:
                    raise SecretsRetrievalError("Secret fetched is not a valid JSON string.")
            else:
                raise SecretsRetrievalError("Binary secrets are not supported.")
                
        else:
            raise SecretsRetrievalError(f"Unknown secrets strategy: {strategy}")
