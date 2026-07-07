"""
Enterprise Smoke Tests
Run immediately after deployment to Dev/QA to ensure connections and variables exist.
Prevents "Broken DAG" errors at runtime caused by missing configuration.
"""
import pytest
from airflow.models import Connection, Variable
from airflow.utils.session import create_session

def test_critical_connections_exist():
    """Verify that essential connections are populated in the environment."""
    required_conns = ['snowflake_default', 'dbt_cloud_default', 'slack_api_default']
    
    with create_session() as session:
        for conn_id in required_conns:
            conn = session.query(Connection).filter(Connection.conn_id == conn_id).first()
            assert conn is not None, f"CRITICAL MISSING CONFIG: Connection '{conn_id}' is not defined."

def test_critical_variables_exist():
    """Verify that environment-specific variables are populated."""
    required_vars = ['prod_variables']
    
    with create_session() as session:
        for var_key in required_vars:
            var = session.query(Variable).filter(Variable.key == var_key).first()
            assert var is not None, f"CRITICAL MISSING CONFIG: Variable '{var_key}' is not defined."
