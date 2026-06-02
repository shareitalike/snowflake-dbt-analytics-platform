# Enterprise Execution & CI/CD Strategy

## End-to-End Execution Flow
In production, the pipeline is orchestrated by Apache Airflow (or dbt Cloud Job Scheduler). The daily/hourly DAG executes the following sequence:

1. **`dbt source freshness`**: Verifies that Fivetran/Kafka actually dropped new data into the Bronze layer. If data is stale, the pipeline aborts to prevent processing outdated metrics.
2. **`dbt seed`**: Reloads static mapping tables (e.g., region codes) if they have changed.
3. **`dbt snapshot`**: Executes SCD Type 2 logic against the Bronze layer to preserve historical states *before* the new data mutates the dimensions.
4. **`dbt run`**: Executes the Directed Acyclic Graph (DAG) from Staging -> Intermediate -> Marts.
5. **`dbt test`**: Asserts Data Contracts. Any test marked `severity: error` immediately halts the pipeline if failed.
6. **`dbt docs generate`**: Rebuilds the Data Catalog, pushing updated descriptions and lineage to the business-facing portal.

*(Note: `dbt build` can be used to run, test, seed, and snapshot simultaneously in topological order).*

## CI/CD Integration (GitHub Actions & Slim CI)

To deploy safely into a production environment managing terabytes of data, we utilize **Slim CI**:

1. **Feature Branch:** An Analytics Engineer creates a branch (`feature/add-margin-calc`) and modifies `fct_sales.sql`.
2. **Pull Request:** They open a PR to the `main` branch.
3. **GitHub Action Triggers Slim CI:** The CI server runs `dbt build --select state:modified+ --defer --state ./prod-run-artifacts`. 
   - *Why this matters:* Instead of rebuilding the entire data warehouse (which takes hours and costs $100s in Snowflake credits), dbt *only* runs `fct_sales.sql` and its downstream dependencies. It defers to the production data for everything upstream, proving the code works safely in exactly 45 seconds.
4. **Approval Workflow:** If all CI tests pass, a Technical Owner (defined in our Data Contracts) must review and approve the PR.
5. **Merge & Deploy:** The code is merged to `main`, and the production Airflow DAG immediately begins utilizing the new logic.

### Rollback Strategy
If bad logic slips into production, the pipeline is reverted by issuing a standard `git revert` on the PR. The next Airflow cycle will pick up the reverted code. For models deployed via `incremental` strategies, a `--full-refresh` flag must be manually passed to the Airflow job to wipe the corrupted physical table and rebuild it from scratch using the restored logic.
