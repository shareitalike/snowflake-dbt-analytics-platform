import logging

try:
    from snowflake.snowpark import DataFrame
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger
from src.exceptions.hierarchy import ConfigurationException

logger = logging.getLogger(__name__)

class LookupManager:
    """
    Orchestrates the resolution of Reference Data across different resolver engines.
    Acts as the main entry point for the pipeline.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def resolve(
        self, 
        df: DataFrame, 
        resolver_type: str, 
        *args, 
        **kwargs
    ) -> DataFrame:
        """
        Routes the lookup request to the appropriate resolving strategy.
        Supported types: 'SURROGATE_KEY', 'BUSINESS_KEY', 'HIERARCHY', 'DIMENSION'
        """
        self.logger.info(f"LookupManager routing request for resolver type: {resolver_type}")
        
        if resolver_type == 'SURROGATE_KEY':
            from src.reference_data.lookup_engine.surrogate_key_resolver import SurrogateKeyResolver
            resolver = SurrogateKeyResolver(self.logger)
            return resolver.resolve_key(df, *args, **kwargs)
            
        elif resolver_type == 'BUSINESS_KEY':
            from src.reference_data.lookup_engine.business_key_resolver import BusinessKeyResolver
            resolver = BusinessKeyResolver(self.logger)
            return resolver.resolve_key(df, *args, **kwargs)
            
        elif resolver_type == 'DIMENSION':
            from src.reference_data.dimensions.dimension_resolver import DimensionResolver
            resolver = DimensionResolver(self.logger)
            return resolver.resolve_dimension(df, *args, **kwargs)
            
        elif resolver_type == 'HIERARCHY':
            from src.reference_data.dimensions.hierarchy_resolver import HierarchyResolver
            resolver = HierarchyResolver(self.logger)
            return resolver.resolve_hierarchy(df, *args, **kwargs)
            
        else:
            msg = f"Unsupported resolver type: {resolver_type}"
            self.logger.error(msg)
            raise ConfigurationException(msg)
