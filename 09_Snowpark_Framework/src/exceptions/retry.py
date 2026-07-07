"""
Module: retry.py
Description: Enterprise Retry Policy using Exponential Backoff with Jitter.
"""
import logging
from functools import wraps
from typing import Callable, Any
from tenacity import (
    retry, 
    stop_after_attempt, 
    wait_exponential_jitter, 
    retry_if_exception_type,
    before_sleep_log
)

from src.exceptions.hierarchy import RetryableException

logger = logging.getLogger(__name__)

def enterprise_retry_policy(max_attempts: int = 3, initial_wait: int = 2, max_wait: int = 60) -> Callable:
    """
    Decorator: Retries a function automatically if it raises a RetryableException.
    Uses exponential backoff with jitter to prevent thundering herd API storms.
    
    Args:
        max_attempts: Total number of execution attempts.
        initial_wait: Minimum wait time in seconds before the first retry.
        max_wait: Absolute maximum wait time in seconds between retries.
    """
    return retry(
        stop=stop_after_attempt(max_attempts),
        wait=wait_exponential_jitter(initial=initial_wait, max=max_wait),
        retry=retry_if_exception_type(RetryableException),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True
    )

def with_retry(func: Callable) -> Callable:
    """
    Syntactic sugar decorator wrapping enterprise_retry_policy with default settings.
    Usage:
        @with_retry
        def execute_snowpark_action(session):
            ...
    """
    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        # We instantiate the retry logic with the default enterprise standards (3 retries).
        retry_decorator = enterprise_retry_policy()
        return retry_decorator(func)(*args, **kwargs)
    
    return wrapper
