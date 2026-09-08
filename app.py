# app.py
"""Streamlit entry point for the ETL Reconciliation platform.
It provides a sidebar navigation to the various pages defined in the
`ui/` package.
"""
import streamlit as st
from ui import dashboard, connections, objects, configuration, execution, results, history, reports

st.set_page_config(page_title="ETL Reconciliation", layout="wide")

# Initialize session state for connections
if "azure_conn" not in st.session_state:
    st.session_state.azure_conn = None
if "snow_conn" not in st.session_state:
    st.session_state.snow_conn = None
if "csv_file" not in st.session_state:
    st.session_state.csv_file = None
if "test_config" not in st.session_state:
    st.session_state.test_config = {}

# Sidebar navigation
pages = {
    "Dashboard": dashboard.page,
    "Connections": connections.page,
    "Data Objects": objects.page,
    "Test Configuration": configuration.page,
    "Run Tests": execution.page,
    "Test Results": results.page,
    "Test History": history.page,
    "Reports": reports.page,
}

st.sidebar.title("Navigation")
selection = st.sidebar.radio("Go to", list(pages.keys()))

# Render selected page
pages[selection]()
