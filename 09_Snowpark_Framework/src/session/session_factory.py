import logging
from typing import Optional
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

# Fallback imports if snowflake-snowpark-python isn't installed locally
try:
    from snowflake.snowpark import Session
    from snowflake.connector.errors import DatabaseError, OperationalError
except ImportError:
    # Mocks for local IDE environment without Snowpark installed
    Session = type('Session', (object,), {})
    DatabaseError = type('DatabaseError', (Exception,), {})
    OperationalError = type('OperationalError', (Exception,), {})

from src.session.config_loader import ConfigLoader, AppConfig
from src.credentials.secrets_manager import SecretsManager
from src.utilities.exceptions import SnowparkConnectionError

logger = logging.getLogger(__name__)

class SnowparkSessionFactory:
    """
    Enterprise Context Manager for Snowflake Sessions.
    Handles credential injection, exponential backoff retries, and graceful shutdown.
    """
    
    def __init__(self, config: Optional[AppConfig] = None):
        self.config = config or ConfigLoader.load_config()
        self.session: Optional[Session] = None
        self._set_retry_params()

    def _set_retry_params(self):
        """
        Dynamically applies retry settings from the validated configuration.
        """
        self._retry_decorator = retry(
            stop=stop_after_attempt(self.config.session.max_retries),
            wait=wait_exponential(
                multiplier=self.config.session.retry_backoff_seconds, 
                min=2, 
                max=60
            ),
            retry=retry_if_exception_type((DatabaseError, OperationalError)),
            reraise=True
        )

    def _build_connection_params(self) -> dict:
        """Constructs the dictionary required for Session.builder"""
        credentials = SecretsManager.get_credentials(
            strategy=self.config.secrets.strategy,
            secret_name=self.config.secrets.secret_name,
            region=self.config.environment.region
        )
        
        return {
            "account": self.config.snowflake.account,
            "user": credentials.get("user"),
            "password": credentials.get("password"),
            "role": self.config.snowflake.role,
            "warehouse": self.config.snowflake.warehouse,
            "database": self.config.snowflake.database,
            "schema": self.config.snowflake.schema_name
        }

    def _connect(self) -> Session:
        """Inner connection method, wrapped by Tenacity dynamically in __enter__."""
        logger.info(f"Connecting to Snowflake Account: {self.config.snowflake.account} "
                    f"using Role: {self.config.snowflake.role}")
        connection_params = self._build_connection_params()
        
        try:
            session = Session.builder.configs(connection_params).create()
            # Health check
            session.sql("SELECT 1").collect()
            logger.info("Snowflake Session established and health check passed.")
            return session
        except Exception as e:
            logger.error(f"Failed to connect to Snowflake: {str(e)}")
            raise

    def __enter__(self) -> Session:
        """
        Context Manager entry point. Wraps connection logic with exponential backoff.
        """
        try:
            # Apply the configured retry decorator to the connection function
            connect_with_retry = self._retry_decorator(self._connect)
            self.session = connect_with_retry()
            return self.session
        except Exception as e:
            raise SnowparkConnectionError(f"Session Factory exhausted retries. Final Error: {str(e)}")

    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Context Manager exit point. Guarantees graceful shutdown.
        """
        if self.session is not None:
            logger.info("Closing Snowflake Session gracefully.")
            try:
                self.session.close()
            except Exception as e:
                logger.warning(f"Error while closing Snowflake session: {str(e)}")
            finally:
                self.session = None
        
        if exc_type is not None:
            logger.error(f"Session terminated due to unhandled exception: {exc_type.__name__}: {exc_val}")
            # Do not swallow the exception
            return False 
