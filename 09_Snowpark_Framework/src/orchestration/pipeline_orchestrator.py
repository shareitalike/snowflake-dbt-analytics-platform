import logging
from typing import Optional, Dict, Any, Callable

try:
    from snowflake.snowpark import Session, DataFrame
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger
from src.audit_metadata.audit.audit_manager import AuditManager, ExecutionTracker
from src.metrics_monitoring.metrics.metrics_collector import MetricsCollector, MetricsPublisher
from src.metrics_monitoring.metrics.metrics_models import PipelineMetrics

logger = logging.getLogger(__name__)

class PipelineOrchestrator:
    """
    The master conductor of the Enterprise Snowpark Framework.
    Wraps the execution logic inside Audit context managers, initializes Metrics collectors,
    and handles global exception routing.
    """
    def __init__(self, session: 'Session', enterprise_logger: EnterpriseLogger):
        self.session = session
        self.logger = enterprise_logger
        self.audit_manager = AuditManager(session, enterprise_logger)
        self.metrics_publisher = MetricsPublisher(session, enterprise_logger)

    def execute(
        self, 
        pipeline_id: str, 
        warehouse: str, 
        business_logic_closure: Callable[['Session', 'ExecutionTracker', MetricsCollector], Dict[str, Any]]
    ) -> bool:
        """
        Executes the provided pipeline logic within the Enterprise Framework scaffolding.
        
        Args:
            pipeline_id: Identifier for the pipeline.
            warehouse: Compute resource.
            business_logic_closure: A function containing the specific pipeline implementation 
                                    (e.g., CDC ingestion, DLQ routing). Must return a dict with
                                    metrics like 'read', 'written', 'rejected'.
                                    
        Returns:
            bool: True if pipeline succeeds without unhandled exceptions, False otherwise.
        """
        self.logger.info(f"Orchestrating Pipeline: {pipeline_id} on {warehouse}")
        metrics_collector = MetricsCollector()
        
        try:
            # 1. Initialize Context Manager (Module 8 - Audit)
            with self.audit_manager.start_job(pipeline_name=pipeline_id, warehouse=warehouse) as tracker:
                
                # 2. Execute Custom Business Logic (Modules 4, 5, 6, 7)
                self.logger.info(f"Invoking core logic for {pipeline_id}")
                result = business_logic_closure(self.session, tracker, metrics_collector)
                
                # 3. Harvest Metrics from logic execution
                rows_read = result.get('rows_read', 0)
                rows_written = result.get('rows_written', 0)
                rows_rejected = result.get('rows_rejected', 0)
                
                # Update Audit Tracker
                tracker.add_metrics(read=rows_read, written=rows_written, rejected=rows_rejected)
                
                # Populate Metric Model (Module 9 - Monitoring)
                pm = PipelineMetrics(
                    pipeline_id=pipeline_id,
                    run_id=tracker.run_id,
                    status="COMPLETED",
                    execution_duration_sec=0.0, # Will be calculated after exit
                    records_read=rows_read,
                    records_written=rows_written,
                    records_rejected=rows_rejected,
                    success_rate=(rows_written / max(1, rows_read)) * 100
                )
                metrics_collector.add_pipeline_metrics(pm)
                
            # 4. Context Manager exits, flushing Audits safely.
            
            # 5. Flush Operational Metrics
            self.metrics_publisher.publish(metrics_collector)
            
            self.logger.info(f"Pipeline {pipeline_id} execution concluded successfully.")
            return True
            
        except Exception as e:
            self.logger.error(f"Catastrophic failure in pipeline {pipeline_id}: {str(e)}", exc_info=True)
            # The Context manager will have already trapped this and set status to FAILED in the audit logs.
            return False
