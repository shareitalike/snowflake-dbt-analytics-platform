import logging

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger
from src.exceptions.hierarchy import DataQualityException

logger = logging.getLogger(__name__)

class EffectiveDateLookup:
    """
    Temporal Lookup Engine for Slowly Changing Dimensions (SCD).
    Ensures historical point-in-time accuracy for reference data joins.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def bounded_join(
        self, 
        transaction_df: DataFrame, 
        reference_df: DataFrame, 
        join_key: str, 
        transaction_date_col: str, 
        ref_effective_col: str = "effective_date", 
        ref_expiry_col: str = "expiry_date"
    ) -> DataFrame:
        """
        Executes a distributed temporal join between transactions and SCD reference data.
        """
        self.logger.info(f"Executing temporal join on {join_key} bounded by {transaction_date_col}.")
        
        # Track initial row count to detect cartesian explosions
        try:
            initial_count = transaction_df.count()
        except Exception:
            initial_count = -1

        # The bounded join condition
        join_condition = (
            (transaction_df[join_key] == reference_df[join_key]) &
            (transaction_df[transaction_date_col] >= reference_df[ref_effective_col]) &
            (transaction_df[transaction_date_col] < reference_df[ref_expiry_col])
        )
        
        # We use a LEFT join so transactions without a matching reference aren't dropped.
        # They will be caught by the FallbackHandler later.
        joined_df = transaction_df.join(reference_df, join_condition, "left")
        
        # If the reference table has overlapping dates, the join will explode the row count.
        # We can optionally validate this if performance allows.
        if initial_count > -1:
            try:
                final_count = joined_df.count()
                if final_count > initial_count:
                    msg = f"Temporal join Cartesian Explosion detected: {initial_count} -> {final_count}. Reference table {join_key} has overlapping date bounds."
                    self.logger.error(msg)
                    raise DataQualityException(msg)
            except DataQualityException:
                raise
            except Exception as e:
                self.logger.warning(f"Could not validate post-join row counts: {str(e)}")

        return joined_df
