"""
Module: exceptions.py
Description: Custom Exception Hierarchy for the Snowpark Framework
"""

class SnowparkFrameworkError(Exception):
    """Base exception for all framework-level errors."""
    pass

class ConfigurationError(SnowparkFrameworkError):
    """Raised when environment variables or TOML parsing fails."""
    pass

class SecretsRetrievalError(SnowparkFrameworkError):
    """Raised when AWS Secrets Manager or Env secrets cannot be loaded."""
    pass

class SnowparkConnectionError(SnowparkFrameworkError):
    """Raised when Snowpark Session Factory fails to connect after max retries."""
    pass

class PreFlightError(SnowparkFrameworkError):
    """Raised when pre-execution validation checks fail."""
    pass

class DataValidationError(SnowparkFrameworkError):
    """Raised when a DataFrame fails quality or schema constraints."""
    pass

class TransformationError(SnowparkFrameworkError):
    """Raised when an error occurs during DataFrame manipulation."""
    pass
