# Enterprise Dynamic DAGs & TaskGroups
## Module 07 - Design Summary

### Why Dynamic DAGs?
In a standard Airflow deployment, if a company has 50 different data domains (Sales, Finance, Inventory, HR, etc.), Data Engineers will often copy-paste the same Python DAG file 50 times, changing only the table names. This is an anti-pattern. It leads to massive codebase bloat and makes refactoring impossible.
By using a **Dynamic DAG Factory**, we abstract the Python code completely. Data Engineers simply add 4 lines of YAML configuration to a central file. The Factory parses the YAML and automatically loops to generate 50 unique Airflow DAGs in memory. 

### Why TaskGroups?
A DAG can quickly become a tangled mess of 100+ tasks on the UI.
**TaskGroups** allow us to bundle related tasks (e.g., Stream Check -> Execute Snowflake Task -> Update Watermark) into a single, collapsible UI element. This makes debugging significantly easier, as failures are visually isolated to a specific logical group.

### Scalability Strategy (Parallel Processing)
The Dynamic Factory doesn't just generate single tasks; it dynamically scales. If the `sales` domain in the YAML defines 15 CDC streams, the Factory dynamically iterates through all 15, instantiates 15 TaskGroups, and wires them up to run in *parallel*. This allows the orchestration layer to scale infinitely with zero Python code changes.
