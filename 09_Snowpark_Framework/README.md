# Phase 09 - Enterprise Snowpark Framework

This directory contains the OmniRetail Enterprise Snowpark Framework. 

This framework provides a production-ready, highly governed Python execution environment for complex data engineering workloads that exceed the practical limits of declarative SQL.

## Module 1: Framework Architecture

This module establishes the core design, directory structure, and strategic foundations of the framework.

### Repository Structure

```text
09_Snowpark_Framework/
├── config/                  # TOML Configuration templates (dev, qa, prod)
│   └── environments/
├── docs/                    # Architecture and runbook documentation
├── src/                     # Core Python Application
│   ├── business_rules/      # Domain-specific logic
│   ├── credentials/         # AWS Secrets Manager / environment var integration
│   ├── framework/           # Core framework orchestration
│   ├── jobs/                # Entrypoints for scheduled execution
│   ├── logging/             # Standardized JSON and table-based logging
│   ├── monitoring/          # Metrics and SLA evaluation
│   ├── session/             # Connection pooling and lifecycle management
│   ├── transformations/     # Reusable, pure DataFrame functions
│   ├── utilities/           # Helpers (date math, schema parsers)
│   └── validators/          # Pre/post execution DataFrame validation
└── tests/                   # Pytest suite
```

### Deliverables Checklist

- [x] **Design Summary:** Why Snowpark, When to use it vs SQL.
- [x] **Repository Structure:** Comprehensive enterprise layout generated.
- [x] **Framework Architecture:** Mermaid diagrams for components and lifecycle.
- [x] **Enterprise Strategies:** Config, Secrets, Logging, Exceptions, Testing, Security.

## Next Steps

**Module 2** will implement the foundational `src/session/` and `config/` components, including the Pydantic configuration loader, AWS Secrets Manager integration, and resilient connection pooling.
