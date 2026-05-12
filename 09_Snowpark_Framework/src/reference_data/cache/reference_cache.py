import logging
from typing import Dict, Any

try:
    from snowflake.snowpark import DataFrame
    from snowflake.snowpark.functions import col, lit, when
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger
from src.exceptions.hierarchy import ConfigurationException

logger = logging.getLogger(__name__)

class ReferenceCache:
    """
    In-Memory Caching Engine for small Reference Data tables.
    Avoids distributed network shuffles for high-frequency lookups.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger, max_rows: int = 100000):
        self.logger = enterprise_logger
        self.max_rows = max_rows
        self._cache: Dict[str, Dict[str, Any]] = {}

    def load_cache(self, cache_name: str, ref_df: DataFrame, key_col: str, value_col: str):
        """
        Pulls a small Snowpark DataFrame into a local Python dictionary.
        """
        self.logger.info(f"Loading reference data '{cache_name}' into memory cache.")
        
        try:
            row_count = ref_df.count()
        except Exception:
            row_count = 0
            
        if row_count > self.max_rows:
            msg = f"Reference table '{cache_name}' exceeds max cache size ({row_count} > {self.max_rows}). Use EffectiveDateLookup instead."
            self.logger.error(msg)
            raise ConfigurationException(msg)
            
        try:
            # Execute the query and pull data into the local python process
            rows = ref_df.select(key_col, value_col).collect()
            # Build the dictionary mapping
            self._cache[cache_name] = {str(row[key_col]): row[value_col] for row in rows}
            self.logger.info(f"Successfully cached {len(self._cache[cache_name])} keys for '{cache_name}'.")
        except Exception as e:
            self.logger.error(f"Failed to load cache '{cache_name}': {str(e)}")
            raise

    def get_dict(self, cache_name: str) -> Dict[str, Any]:
        """Returns the raw dictionary for UDF mapping."""
        if cache_name not in self._cache:
            raise ConfigurationException(f"Cache '{cache_name}' not loaded.")
        return self._cache[cache_name]
