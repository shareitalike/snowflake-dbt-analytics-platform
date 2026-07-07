import logging
from typing import List, Dict

try:
    from snowflake.snowpark import Session
except ImportError:
    pass

from src.logging.loggers import EnterpriseLogger

logger = logging.getLogger(__name__)

class LineageNode:
    """Represents a node in the Data Lineage Graph."""
    def __init__(self, node_id: str, node_type: str, layer: str):
        self.node_id = node_id        # e.g. 'DB_PROD_RAW.SC_SHOPIFY.TB_ORDERS' or 'GMV_KPI'
        self.node_type = node_type    # e.g. 'TABLE', 'VIEW', 'MODEL', 'SOURCE', 'KPI', 'REPORT'
        self.layer = layer            # e.g. 'BRONZE', 'SILVER', 'GOLD', 'API', 'BUSINESS_METRIC'

class LineageEdge:
    """Represents a directional dependency."""
    def __init__(self, source_id: str, target_id: str, pipeline_id: str, lineage_type: str):
        self.source_id = source_id
        self.target_id = target_id
        self.pipeline_id = pipeline_id
        self.lineage_type = lineage_type  # 'TECHNICAL' or 'BUSINESS'

class LineageTracker:
    """
    Manages End-to-End Enterprise Data Lineage.
    Supports both Technical lineage (Pipeline data flow) and Business lineage (Metric derivations).
    """
    def __init__(self, session: 'Session', enterprise_logger: EnterpriseLogger):
        self.session = session
        self.logger = enterprise_logger
        self.nodes: Dict[str, LineageNode] = {}
        self.edges: List[LineageEdge] = []

    def _register_dependency(self, source: LineageNode, target: LineageNode, pipeline_id: str, lineage_type: str):
        self.nodes[source.node_id] = source
        self.nodes[target.node_id] = target
        
        edge = LineageEdge(source.node_id, target.node_id, pipeline_id, lineage_type)
        self.edges.append(edge)
        
        self.logger.info(f"[{lineage_type}] Lineage Registered: {source.node_id} -> {target.node_id} (Context: {pipeline_id})")

    def register_technical_dependency(self, source: LineageNode, target: LineageNode, pipeline_id: str):
        """
        Registers physical data movement.
        Example: Shopify API -> S3 -> Snowpipe -> Bronze -> Stream -> Task -> Silver -> dbt -> Gold -> PowerBI
        """
        self._register_dependency(source, target, pipeline_id, "TECHNICAL")
        
    def register_business_dependency(self, source: LineageNode, target: LineageNode, business_context: str):
        """
        Registers conceptual metric derivations.
        Example: Shopify Orders -> Sales Fact -> GMV KPI
        """
        self._register_dependency(source, target, business_context, "BUSINESS")

    def flush_lineage(self):
        """
        Writes the registered nodes and edges to the Metadata Control tables.
        This enables recursive graph queries (CONNECT BY) in Snowflake.
        """
        self.logger.info(f"Flushing {len(self.edges)} Lineage Edges to DB_PROD_METADATA.SC_META_CONTROL.TB_LINEAGE")
        
        # In a real environment:
        # 1. UPSERT Nodes into TB_LINEAGE_NODES
        # 2. UPSERT Edges into TB_LINEAGE_EDGES
        pass
