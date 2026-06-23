"""
Enterprise Dynamic DAG Factory
Parses the domain_config.yaml and dynamically generates Airflow DAGs.
If a new table or domain is added to the business, Data Engineers simply add 4 lines 
to the YAML file. ZERO Python code needs to be written.
"""
import yaml
import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from callbacks.enterprise_callbacks import enterprise_failure_callback
from taskgroups.standard_ingestion_tg import build_cdc_ingestion_taskgroup

# Load YAML Config
CONFIG_PATH = os.path.join(os.path.dirname(__file__), '../config/domain_config.yaml')

with open(CONFIG_PATH, 'r') as file:
    config = yaml.safe_load(file)

# Iterate through every pipeline in the YAML and generate a DAG dynamically
for pipeline in config.get('domains', []):
    
    dag_id = f"dynamic_{pipeline['pipeline_name']}_dag"
    
    default_args = {
        'owner': pipeline['owner'],
        'depends_on_past': False,
        'retries': pipeline['retries'],
        'retry_delay': timedelta(minutes=5),
        'sla': timedelta(hours=pipeline['sla_hours']),
        'on_failure_callback': enterprise_failure_callback,
    }

    # Dynamically instantiate the DAG object and assign it to the global namespace
    # so Airflow's DAG processor can pick it up.
    globals()[dag_id] = DAG(
        dag_id=dag_id,
        default_args=default_args,
        description=f"Auto-generated pipeline for {pipeline['pipeline_name']} from {pipeline['source_system']}.",
        schedule_interval=pipeline['schedule_interval'],
        start_date=datetime(2026, 1, 1),
        catchup=False,
        tags=pipeline['tags'],
    )
    
    # Build the DAG structure
    with globals()[dag_id] as dag:
        start = EmptyOperator(task_id='start')
        end = EmptyOperator(task_id='end')
        
        # Parallel Processing Strategy:
        # We loop through every CDC stream defined in the YAML for this pipeline.
        # We generate a complex TaskGroup for each stream, and run them all in parallel.
        for stream_def in pipeline.get('streams_to_process', []):
            stream_name = stream_def['stream_name']
            task_name = stream_def['task_name']
            
            # Generate the modular TaskGroup
            tg = build_cdc_ingestion_taskgroup(
                group_id=f"process_group_{stream_name}",
                stream_name=stream_name,
                task_name=task_name
            )
            
            # Wire up dependencies (Fanning out in parallel)
            start >> tg >> end
