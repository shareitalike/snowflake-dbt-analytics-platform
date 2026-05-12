import logging
from typing import List

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, coalesce, lit, when, array_append, array_construct
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class FallbackHandler:
    """
    Handles missing lookup values by assigning defaults and flagging warnings,
    rather than dropping the transaction row.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def apply_fallback(self, df: DataFrame, target_col: str, default_value: str, flag_warning: bool = True) -> DataFrame:
        """
        Replaces NULLs in the target lookup column with a default value.
        Optionally appends a warning message to a LOOKUP_WARNINGS array.
        """
        self.logger.info(f"Applying fallback '{default_value}' for missing lookups on '{target_col}'.")
        
        # Replace NULL with default
        resolved_df = df.with_column(
            target_col, 
            coalesce(col(target_col), lit(default_value))
        )
        
        if flag_warning:
            warning_msg = f"MISSING_LOOKUP_{target_col.upper()}"
            
            # If the row used the default value, append the warning
            # We assume a column LOOKUP_WARNINGS (ARRAY) exists or we initialize it.
            # For simplicity in this framework demonstration, we'll create a simple string flag
            # or append to an array if it exists.
            resolved_df = resolved_df.with_column(
                f"{target_col}_WARNING",
                when(col(target_col) == lit(default_value), lit(warning_msg)).else_(lit(None))
            )
            
        return resolved_df
