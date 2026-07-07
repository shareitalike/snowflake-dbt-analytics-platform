import logging
from typing import Dict, Any

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class SchemaDetector:
    """
    Manages Schema Evolution and Mapping definition for JSON payloads.
    """
    def __init__(self, enterprise_logger: EnterpriseLogger):
        self.logger = enterprise_logger

    def build_extraction_map(self, base_map: Dict[str, Dict[str, Any]], version_overrides: Dict[str, Dict[str, Any]] = None) -> Dict[str, Dict[str, Any]]:
        """
        Builds the final extraction map by merging base schema definitions with version-specific overrides.
        Allows the framework to gracefully handle API version upgrades (e.g. Stripe API v1 to v2).
        """
        final_map = base_map.copy()
        
        if version_overrides:
            self.logger.info(f"Applying {len(version_overrides)} schema version overrides.")
            for col_name, config in version_overrides.items():
                if col_name in final_map:
                    self.logger.info(f"Overriding path for {col_name}: {final_map[col_name]['path']} -> {config['path']}")
                final_map[col_name] = config
                
        return final_map
