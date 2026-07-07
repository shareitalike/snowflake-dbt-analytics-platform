import logging

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, coalesce, lit, when
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger
from src.exceptions.hierarchy import DataQualityException

logger = logging.getLogger(__name__)

class BusinessKeyResolver:
    """
    Resolves human-readable Business Keys (e.g., 'USD', 'US') from Reference Tables.
    Typically used for small domains like Currency, Country, or Status.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def resolve_key(
        self, 
        df: DataFrame, 
        ref_df: DataFrame, 
        join_key: str, 
        target_value_col: str,
        transaction_date_col: str,
        default_fallback: str = "UNMAPPED",
        ref_start_col: str = "effective_start_date",
        ref_end_col: str = "effective_end_date"
    ) -> DataFrame:
        """
        Performs a temporal bounded join and assigns fallback values.
        """
        self.logger.info(f"Resolving Business Key '{join_key}' -> '{target_value_col}' using temporal bounds.")
        
        # Build bounded condition
        join_condition = (
            (df[join_key] == ref_df[join_key]) &
            (df[transaction_date_col] >= ref_df[ref_start_col]) &
            (df[transaction_date_col] < ref_df[ref_end_col])
        )
        
        # Execute LEFT join
        joined_df = df.join(ref_df, join_condition, "left")
        
        # Apply Fallback & Warning
        resolved_df = joined_df.with_column(
            target_value_col,
            coalesce(ref_df[target_value_col], lit(default_fallback))
        ).with_column(
            f"{target_value_col}_WARNING",
            when(ref_df[target_value_col].is_null(), lit(f"MISSING_BUSINESS_KEY_{join_key}")).else_(lit(None))
        )
        
        # Drop reference columns to keep namespace clean, except the newly resolved target column
        # In practice, explicit select() is safer, but this conceptually demonstrates the pattern.
        return resolved_df
