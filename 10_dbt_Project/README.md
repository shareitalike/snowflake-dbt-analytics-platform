# Phase 10 - Enterprise dbt Cloud Project

This module establishes the foundational architecture for the Enterprise dbt Cloud implementation. It transitions the project from Python-based imperative data engineering (Snowpark) to SQL-based declarative Analytics Engineering.

## Architecture Deliverables
- [x] **Project Scaffolding:** Generated the enterprise repository structure adhering to dbt Labs best practices (`models/staging`, `models/marts/facts`, etc.).
- [x] **Configuration (`dbt_project.yml`):** Configured materialization strategies at the folder level. Staging is default `view`, Intermediate is `ephemeral`, Facts are `incremental`.
- [x] **Profiles (`profiles.yml`):** Established environment isolation (Dev vs Prod) utilizing Snowflake Key-Pair authentication.
- [x] **Dependencies (`packages.yml`):** Integrated standard enterprise packages (`dbt_utils`, `dbt_expectations`).
- [x] **Selectors (`selectors.yml`):** Built execution subsets for Slim CI (`state:modified+1`) and high-frequency incremental runs.

## Next Steps
This module concludes the architectural setup. Subsequent modules will generate the actual SQL `.sql` models and schema `.yml` files to populate the Silver and Gold layers based on the Phase 04 Enterprise Data Model.
