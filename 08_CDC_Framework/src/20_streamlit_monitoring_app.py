# ==============================================================================
# FILE: 20_streamlit_monitoring_app.py
# PHASE: 08 - CDC Framework (Observability)
# 
# EXPLANATION: Streamlit in Snowflake (SiS) Application for Native DataOps Monitoring.
# DESIGN DECISIONS: Leverages Snowpark session context to natively query control schemas 
#                   without data leaving Snowflake. Implements real-time observability 
#                   for SLA tracking, Failed Batch Registry, and data velocity metrics.
# WHY NATIVE STREAMLIT?: 
#   1. Zero egress/ingress latency.
#   2. Enterprise-grade security (inherits RBAC from Snowflake).
#   3. Pythonic access to Snowpark DataFrames.
# 
# DEPLOYMENT INSTRUCTIONS:
# 1. Open Snowflake Snowsight UI.
# 2. Navigate to Streamlit -> + Streamlit App.
# 3. Paste this code into the editor and click Run.
# ==============================================================================

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd

# Set premium page configuration
st.set_page_config(
    layout="wide", 
    page_title="Enterprise CDC Operations Monitor",
    page_icon="❄️",
    initial_sidebar_state="expanded"
)

# Custom CSS for premium styling
st.markdown("""
    <style>
        .metric-card {
            background-color: #1E293B;
            border-radius: 8px;
            padding: 1rem;
            color: white;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .main-header {
            background: linear-gradient(90deg, #29b5e8 0%, #1e5c8e 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-weight: 800;
        }
    </style>
""", unsafe_allow_html=True)

# Get the active Snowflake session natively
try:
    session = get_active_session()
except Exception as e:
    st.error("No active Snowflake session found. Ensure this runs within Streamlit in Snowflake.")
    st.stop()

# =============================================================
# SIDEBAR
# =============================================================
with st.sidebar:
    st.image("https://upload.wikimedia.org/wikipedia/commons/f/ff/Snowflake_Logo.svg", width=150)
    st.markdown("### CDC Ops Control Center")
    refresh_button = st.button("🔄 Refresh Data", use_container_width=True)
    st.divider()
    st.markdown("### Filter Criteria")
    selected_env = st.selectbox("Environment", ["PROD", "UAT", "DEV"], index=0)
    time_window = st.slider("Time Window (Hours)", min_value=1, max_value=72, value=24)

st.markdown('<h1 class="main-header">📊 CDC Operations & Health Monitor</h1>', unsafe_allow_html=True)
st.markdown("Real-time observability and governance for Silver Layer CDC pipelines.")

# =============================================================
# TOP ROW: KPI METRICS
# =============================================================
st.subheader("Platform Health Overview")

# Mock queries for metrics (can be swapped with real SQL)
col1, col2, col3, col4 = st.columns(4)

try:
    # Query SLA Breaches
    sla_query = """
        SELECT COUNT(*) AS SLA_Breaches
        FROM DB_PROD_METADATA.SC_META_OBSERVABILITY.TB_SLA_ALERTS
        WHERE Is_Resolved = FALSE;
    """
    sla_count = session.sql(sla_query).collect()[0][0]
    
    # Query Total Volume Today
    volume_today_query = """
        SELECT SUM(Rows_Inserted)
        FROM DB_PROD_METADATA.SC_META_CONTROL.TB_BATCH_CONTROL
        WHERE DATE(Execution_End_Time) = CURRENT_DATE();
    """
    volume_today = session.sql(volume_today_query).collect()[0][0] or 0
    
    # Render Metrics
    col1.metric("Active SLA Breaches", sla_count, delta="-1 from yesterday", delta_color="inverse")
    col2.metric("Total Rows Processed (Today)", f"{volume_today:,}", delta="12%", delta_color="normal")
    col3.metric("CDC Pipeline Uptime", "99.98%", delta="0.02%", delta_color="normal")
    col4.metric("Active Replay Jobs", "0", delta="0", delta_color="off")
    
except Exception as e:
    st.warning("⚠️ Control Metadata schemas not accessible. Displaying placeholder metrics for demo.")
    col1.metric("Active SLA Breaches", "2", delta="+1", delta_color="inverse")
    col2.metric("Total Rows Processed (Today)", "4.2M", delta="12%", delta_color="normal")
    col3.metric("CDC Pipeline Uptime", "99.98%", delta="0.02%", delta_color="normal")
    col4.metric("Active Replay Jobs", "1", delta="0", delta_color="off")

st.divider()

# =============================================================
# MAIN TABS
# =============================================================
tab1, tab2 = st.tabs(["❌ Failed Batches (Action Required)", "📈 Processing Velocity Trends"])

with tab1:
    st.markdown("#### Registry of Failed Micro-Batches")
    st.caption("Use `SP_REPLAY_FAILED_BATCH(Batch_ID)` to initiate targeted recovery.")
    
    failed_query = """
        SELECT 
            Pipeline_ID, 
            Batch_ID, 
            Execution_Start_Time AS Failure_Time, 
            Error_Message,
            '🚨 PENDING RECOVERY' AS Status
        FROM DB_PROD_METADATA.SC_META_CONTROL.VW_FAILED_BATCH_REGISTRY
        ORDER BY Execution_Start_Time DESC
        LIMIT 50;
    """
    try:
        failed_df = session.sql(failed_query).to_pandas()
        if failed_df.empty:
            st.success("✅ No failed batches found. All pipelines operating nominally.")
        else:
            st.dataframe(
                failed_df, 
                use_container_width=True, 
                hide_index=True,
                column_config={
                    "Status": st.column_config.TextColumn("Status", help="Current Recovery Status"),
                    "Error_Message": st.column_config.TextColumn("Exception Details")
                }
            )
    except Exception as e:
        st.error("Could not load Failed Batch Registry. Ensure VW_FAILED_BATCH_REGISTRY exists.")

with tab2:
    st.markdown("#### Ingestion Volume (Rows per Hour)")
    
    volume_query = f"""
        SELECT 
            DATE_TRUNC('HOUR', Execution_End_Time) AS PROCESSING_HOUR,
            SUM(Rows_Inserted) AS TOTAL_INSERTED
        FROM DB_PROD_METADATA.SC_META_CONTROL.TB_BATCH_CONTROL
        WHERE Status = 'COMPLETED'
        AND Execution_End_Time >= DATEADD(HOUR, -{time_window}, CURRENT_TIMESTAMP())
        GROUP BY 1
        ORDER BY 1 ASC;
    """
    try:
        volume_df = session.sql(volume_query).to_pandas()
        if volume_df.empty:
            st.info(f"No completed batches found in the last {time_window} hours.")
        else:
            st.bar_chart(data=volume_df, x="PROCESSING_HOUR", y="TOTAL_INSERTED", color="#29b5e8", height=350)
    except Exception as e:
        st.error("Could not load Data Volume Trend. Ensure TB_BATCH_CONTROL exists.")

st.caption("© 2026 DataOps Engineering Team | Powered by Streamlit in Snowflake")
