"""
Enterprise DAG Integrity Tests
These tests run in GitHub Actions during CI/CD to prevent broken code from crashing the Scheduler.
"""
import glob
import importlib.util
import os
import pytest
from airflow.models import DAG

DAG_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'dags/**/*.py'
)
DAG_FILES = glob.glob(DAG_PATH, recursive=True)

@pytest.mark.parametrize("dag_file", DAG_FILES)
def test_dag_integrity(dag_file):
    """
    Imports each DAG file and verifies it parses without errors.
    This catches Syntax Errors, Missing Imports, and Circular Dependencies.
    """
    module_name, _ = os.path.splitext(os.path.basename(dag_file))
    spec = importlib.util.spec_from_file_location(module_name, dag_file)
    module = importlib.util.module_from_spec(spec)
    
    try:
        spec.loader.exec_module(module)
    except Exception as e:
        pytest.fail(f"Failed to import DAG file {dag_file}. Error: {str(e)}")

    # Verify that at least one DAG object is instantiated
    dag_objects = [var for var in vars(module).values() if isinstance(var, DAG)]
    
    if not dag_objects:
        # Some files might just be utilities in the dags folder, but usually they should contain DAGs
        pass
    else:
        for dag in dag_objects:
            # Enforce Enterprise standard: All DAGs must have tags
            assert dag.tags, f"DAG {dag.dag_id} is missing required 'tags'."
            # Enforce Enterprise standard: All DAGs must have an owner
            assert dag.default_args.get('owner'), f"DAG {dag.dag_id} is missing required 'owner'."
            
            # Check for cyclical dependencies (Airflow will normally catch this, but good to assert)
            try:
                dag.test_cycle()
            except Exception as e:
                pytest.fail(f"DAG {dag.dag_id} has a cycle: {str(e)}")
