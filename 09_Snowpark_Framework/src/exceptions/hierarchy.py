"""
Module: hierarchy.py
Description: Centralized Enterprise Exception Hierarchy
"""

class ApplicationException(Exception):
    """Base exception for all Snowpark framework exceptions."""
    pass

# ==============================================================================
# Retryable Exceptions (Transient Failures)
# ==============================================================================
class RetryableException(ApplicationException):
    """Base exception for errors that should be retried automatically."""
    pass

class SnowflakeConnectionException(RetryableException):
    """Raised when Snowflake API times out, drops connection, or throttles."""
    pass

class NetworkException(RetryableException):
    """Raised during transient external API calls (e.g., REST endpoints inside a UDF)."""
    pass

class WarehouseQueueException(RetryableException):
    """Raised when the Warehouse is overloaded and cannot accept the query."""
    pass

# ==============================================================================
# Non-Retryable Exceptions (Permanent Failures)
# ==============================================================================
class NonRetryableException(ApplicationException):
    """Base exception for errors that require code or data fixes. Fails immediately."""
    pass

class ConfigurationException(NonRetryableException):
    """Raised when environment variables or TOML parsing fails."""
    pass

class ValidationException(NonRetryableException):
    """Base class for validation failures."""
    pass

class SchemaValidationException(ValidationException):
    """Raised when expected columns are missing or data types drift."""
    pass

class DataQualityException(ValidationException):
    """Raised when data violates constraints (e.g., > 10% nulls)."""
    pass

class BusinessRuleException(NonRetryableException):
    """Raised when domain-specific business rules are violated."""
    pass

class SQLExecutionException(NonRetryableException):
    """Raised on invalid SQL syntax or compilation failure from AST."""
    pass

# ==============================================================================
# Orchestration Exceptions
# ==============================================================================
class PipelineException(ApplicationException):
    """Raised for high-level DAG orchestration failures."""
    pass
