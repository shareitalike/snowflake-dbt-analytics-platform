# Project Rules & Guidelines

## dbt Module Execution Guidelines
For every dbt module, ensure the following instruction is applied to the output and architecture generation:

> Generate code that adheres to current dbt Core and dbt Cloud best practices. Prefer maintainability, readability, modularity, and production suitability over unnecessary complexity. Where multiple valid approaches exist, briefly explain the trade-offs and why the chosen design fits this enterprise retail project.

## dbt Model Generation Requirements
For every dbt model that is generated, you MUST also generate and/or document:
- `schema.yml` documentation
- Appropriate dbt tests
- Model description
- Tags (domain, layer, owner)
- Materialization choice with justification
- Performance considerations (clustering, incremental strategy if applicable)
- Downstream dependencies
- Upstream dependencies
- Expected row counts
- Estimated refresh frequency
- Suggested cluster keys
