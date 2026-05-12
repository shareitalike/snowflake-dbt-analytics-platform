# Interview Notes: Snowpark Framework

## "Why do you use TOML files in your Snowpark Framework instead of hardcoding database names in Python?"
**Answer:** In an enterprise environment, we use `.toml` (Tom's Obvious, Minimal Language) configuration files to completely separate our **Configuration** from our **Code**. 

If we hardcode `DB_PROD_CURATED` or `WH_TRANSFORM` directly inside our Python Snowpark scripts, we can never safely test that code in a development environment without manually changing the code. By using `dev.toml`, `qa.toml`, and `prod.toml`, our Python code remains 100% environment-agnostic. 

When our CI/CD pipeline runs the Snowpark code, it passes an environment flag (e.g., `--env dev`). The Python framework reads the `dev.toml` file, dynamically pulls the correct Snowflake Role (`DATA_ENGINEER_DEV`), Database (`DB_DEV_CURATED`), and Warehouse, and builds the Snowpark `Session`. This is a mandatory best practice for DevOps and CI/CD compliance in Data Engineering.

### "Can you show me how you actually parse that TOML file in your Python code?"
*(If an interviewer asks you to prove you know how to write the code to load configurations, you write this pattern)*

**Answer:** We use the native Python `toml` (or `tomllib` in 3.11+) library to parse the file into a Python dictionary, and pass that dictionary directly to the Snowpark `Session.builder`.

```python
import toml
import os
from snowflake.snowpark import Session

def create_snowpark_session(env_name: str) -> Session:
    """Dynamically builds a Snowpark session based on the environment."""
    
    # 1. Dynamically load the correct TOML file (dev.toml, prod.toml)
    config_path = f"config/environments/{env_name}.toml"
    with open(config_path, "r") as f:
        config = toml.load(f)
    
    # 2. Extract the [snowflake] section as a dictionary
    sf_connection_params = config["snowflake"]
    
    # 3. Securely fetch the password based on the strategy in the TOML file
    # We NEVER store passwords in the TOML file!
    if config["secrets"]["strategy"] == "env":
        sf_connection_params["password"] = os.getenv("SNOWFLAKE_PASSWORD")
    elif config["secrets"]["strategy"] == "aws_secrets_manager":
        sf_connection_params["password"] = fetch_aws_secret(config["secrets"]["secret_name"])
        
    # 4. Build and return the Snowpark Session
    session = Session.builder.configs(sf_connection_params).create()
    return session
```
This proves you know how to write production-grade, secure, and environment-agnostic Python code!
