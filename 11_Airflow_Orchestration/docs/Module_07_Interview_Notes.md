# Interview Notes: Dynamic DAGs & TaskGroups

## Q: How do you avoid duplicate DAG code across hundreds of pipelines?
**A:** "I strictly follow the DRY (Don't Repeat Yourself) principle by building a **Metadata-Driven Pipeline Registry**. I abstract the pipeline logic into a generic Python DAG Factory that reads from a YAML or JSON metadata registry. If a new business unit needs to onboard a pipeline, they don't write Airflow code. They submit a Pull Request adding 10 lines of configuration (Pipeline Name, Source System, Target Schema, SLA, Warehouse, dbt Job ID) to the registry. The Factory parses this and dynamically generates the DAG. No one copy-pastes Python code in my repository."

## Q: When should you use TaskGroups instead of SubDAGs?
**A:** "SubDAGs are a deprecated Airflow anti-pattern. They launch their own independent executor, cause massive scheduler deadlocks, and hide logs from the main UI. I always use TaskGroups. A TaskGroup is purely a UI abstraction—it groups tasks visually on the graph without changing how the scheduler executes them under the hood."

## Q: How do you scale Airflow to handle dynamic metadata?
**A:** "The key is protecting the Scheduler. The Scheduler parses every DAG file every 30-60 seconds. If you query Snowflake inside the DAG factory to dynamically generate tasks, you will crash the Airflow Scheduler. You must decouple it. I use a CI/CD process to dump Snowflake metadata into a static JSON/YAML file, and then the Airflow Factory reads that static file instantly. This guarantees O(1) parsing time."

## Enterprise Best Practices Demonstrated
1. **Metadata-Driven Orchestration:** Separating configuration (YAML) from code (Python).
2. **Failure Isolation:** Using TaskGroups so that if `sales_line_item_stream` fails, `sales_order_stream` continues processing in parallel without impacting the rest of the domain.
