# ==============================================================================
# FILE: 20_streamlit_monitoring_app.py
# PHASE: 08 - CDC Framework
# 
# EXPLANATION: This is the source code for the Streamlit in Snowflake (SiS) DataOps Dashboard. It replaces legacy Snowsight Dashboards.
# DESIGN DECISIONS: Uses Snowpark session.sql() to query the metadata control schema. Renders SLA alerts, a Failed Batch table, and an hourly processing volume chart.
# WHY: Observability is a core Data Engineering requirement. Building this natively in Snowflake using Streamlit provides the DataOps team with a real-time, interactive interface to monitor pipeline health and identify Batch IDs that require recovery, without needing external BI tools.
# 
# DEPLOYMENT INSTRUCTIONS:
# 1. Open Snowflake Web UI.
# 2. Go to Streamlit -> + Streamlit App.
# 3. Paste this code into the editor and click Run.
# ==============================================================================

import streamlit as st
from snowflake.snowpark.context import get_active_session

# Set page configuration
st.set_page_config(layout="wide", page_title="CDC Operations Monitor")

st.title("📊 CDC Operations & Health Monitor")
st.markdown("Real-time observability for the Silver Layer CDC pipelines.")

# Get the active Snowflake session
session = get_active_session()

# =============================================================
# TILE 1: SLA Breaches (Alert Banner)
# =============================================================
st.subheader("SLA Status")
sla_query = """
    SELECT COUNT(*) AS SLA_Breaches
    FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_SLA_ALERTS
    WHERE Is_Resolved = FALSE;
"""
try:
    sla_count = session.sql(sla_query).collect()[0][0]
    if sla_count > 0:
        st.error(f"🚨 **WARNING:** There are {sla_count} ACTIVE SLA BREACHES. Please check the Observability schema immediately.")
    else:
        st.success("✅ **All Pipelines Healthy** (0 SLA Breaches)")
except Exception as e:
    st.warning("⚠️ SLA Table not found or inaccessible. Have you deployed the observability schema?")

st.divider()

# Create two columns for the next tiles
col1, col2 = st.columns([1, 1])

# =============================================================
# TILE 2: Failed Batches Registry (Table)
# =============================================================
with col1:
    st.subheader("❌ Failed Batches (Action Required)")
    st.caption("Copy the Batch_ID and use SP_REPLAY_FAILED_BATCH() to recover.")
    
    failed_query = """
        SELECT 
            Pipeline_ID, 
            Batch_ID, 
            Execution_Start_Time, 
            Error_Message 
        FROM DB_PROD_METADATA.SC_META_CONTROL.VW_FAILED_BATCH_REGISTRY
        ORDER BY Execution_Start_Time DESC;
    """
    try:
        failed_df = session.sql(failed_query).to_pandas()
        if failed_df.empty:
            st.info("No failed batches found in the registry.")
        else:
            st.dataframe(failed_df, use_container_width=True, hide_index=True)
    except Exception as e:
        st.error("Could not load Failed Batch Registry.")

# =============================================================
# TILE 3: Data Volume Trend (Bar Chart)
# =============================================================
with col2:
    st.subheader("📈 Hourly Processing Volumes (Last 24 Hours)")
    st.caption("Tracks the total rows inserted into the Silver layer per hour.")
    
    volume_query = """
        SELECT 
            DATE_TRUNC('HOUR', Execution_End_Time) AS Processing_Hour,
            SUM(Rows_Inserted) AS Total_Inserted
        FROM DB_PROD_METADATA.SC_META_CONTROL.TB_BATCH_CONTROL
        WHERE Status = 'COMPLETED'
        GROUP BY 1
        ORDER BY 1 ASC
        LIMIT 24;
    """
    try:
        volume_df = session.sql(volume_query).to_pandas()
        if volume_df.empty:
            st.info("No completed batches found in the last 24 hours.")
        else:
            # Streamlit automatically visualizes pandas dataframes
            st.bar_chart(data=volume_df, x="PROCESSING_HOUR", y="TOTAL_INSERTED", color="#29b5e8")
    except Exception as e:
        st.error("Could not load Data Volume Trend.")

st.divider()
st.caption("DataOps App built with Streamlit in Snowflake (SiS). Queries run against DB_PROD_METADATA.SC_META_CONTROL.")
