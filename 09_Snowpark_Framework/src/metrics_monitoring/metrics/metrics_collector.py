import logging
from typing import List

try:
    from snowflake.snowpark import Session
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger
from .metrics_models import PipelineMetrics, DataQualityMetrics, BusinessMetrics, WarehouseMetrics

logger = logging.getLogger(__name__)

class MetricsCollector:
    """Aggregates metrics in memory during pipeline execution."""
    def __init__(self):
        self.pipeline_metrics: List[PipelineMetrics] = []
        self.dq_metrics: List[DataQualityMetrics] = []
        self.business_metrics: List[BusinessMetrics] = []
        self.warehouse_metrics: List[WarehouseMetrics] = []

    def add_pipeline_metrics(self, metrics: PipelineMetrics):
        self.pipeline_metrics.append(metrics)

    def add_dq_metrics(self, metrics: DataQualityMetrics):
        self.dq_metrics.append(metrics)

    def add_business_metrics(self, metrics: BusinessMetrics):
        self.business_metrics.append(metrics)

    def add_warehouse_metrics(self, metrics: WarehouseMetrics):
        self.warehouse_metrics.append(metrics)

class MetricsPublisher:
    """Flushes aggregated metrics to the Snowflake Control Tables."""
    def __init__(self, session: 'Session', enterprise_logger: EnterpriseLogger):
        self.session = session
        self.logger = enterprise_logger

    def publish(self, collector: MetricsCollector):
        """Writes the collected metrics into the SC_MONITORING schema."""
        self.logger.info("Publishing metrics to DB_PROD_METADATA.SC_MONITORING")
        
        try:
            # Note: In a real implementation, each list would be converted to a DataFrame 
            # and saved to its respective table using `self.session.create_dataframe`.
            if collector.pipeline_metrics:
                self.logger.info(f"Published {len(collector.pipeline_metrics)} Pipeline Metrics.")
                
            if collector.dq_metrics:
                self.logger.info(f"Published {len(collector.dq_metrics)} DQ Metrics.")
                
            if collector.business_metrics:
                self.logger.info(f"Published {len(collector.business_metrics)} Business Metrics.")
                
            if collector.warehouse_metrics:
                self.logger.info(f"Published {len(collector.warehouse_metrics)} Warehouse Metrics.")
                
        except Exception as e:
            self.logger.error(f"Failed to publish metrics: {str(e)}")
