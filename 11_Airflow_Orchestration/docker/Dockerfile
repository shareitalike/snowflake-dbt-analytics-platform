FROM apache/airflow:2.8.1-python3.10

# ENTERPRISE AIRFLOW DOCKERFILE
# This image serves as the baseline for the Local Development environment
# as well as the Production deployment image.

USER root

# Install system dependencies required for Snowflake, dbt, and AWS integrations
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         build-essential \
         git \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Copy enterprise requirements
COPY ../config/requirements.txt /requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt

# Create standard directories inside the container
RUN mkdir -p /opt/airflow/dags /opt/airflow/plugins /opt/airflow/logs
