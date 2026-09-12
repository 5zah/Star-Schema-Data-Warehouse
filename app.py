"""
Flask Web Application & API Server for ETL Data Warehouse Testing Automation.
Features:
- Live Connection Manager for Azure SQL, Snowflake, and File Sources
- Dynamic Table / View / Schema Discovery
- Interactive Reconciliation Engine (File vs Table, Azure SQL vs Azure SQL, Azure SQL vs Snowflake)
- Pytest Automation Test Suite Runner (Run all at once or run selected test scenario's script)
- Comprehensive Reporting & Drilldown Inspector (Fetch report for any scenario, download HTML/JSON/Excel)
"""
import os
import sys
import io
import json
import subprocess
import datetime
import pandas as pd
from flask import Flask, render_template, jsonify, request, send_from_directory
from flask_cors import CORS

# Add root folder to python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from src.connectors.connection_manager import ConnectionManager
from src.reconciliation.sales_reconciler import SalesReconciliationEngine
from src.warehouse.sales_dw_builder import setup_all_sales_warehouses

app = Flask(__name__, template_folder="templates")
CORS(app)

REPORTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "reports"))
DATA_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "data"))
CONFIG_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "config"))

conn_mgr = ConnectionManager()
reconciler = SalesReconciliationEngine(conn_mgr)

# Available Pytest Scenarios Metadata
PYTEST_SCENARIOS = [
    {
        "id": "all",
        "name": "Execute All Automated Test Suites (Full Suite)",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "Full Pipeline",
        "description": "Runs all 12 validation suites covering Files vs Azure SQL, Transformations, Parity, Views & Integrity."
    },
    {
        "id": "test_01_csv_file_vs_azure_sql_staging_volume",
        "name": "CSV File vs Azure SQL Staging Volume",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "File vs Table",
        "description": "Verifies that total row count in raw CSV file matches Azure SQL Staging (stg_sales_transactions)."
    },
    {
        "id": "test_02_csv_file_vs_azure_sql_staging_schema_and_keys",
        "name": "CSV File vs Azure SQL Schema & Keys",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "File vs Table",
        "description": "Asserts required columns and datatypes are preserved during file-to-table staging ingestion."
    },
    {
        "id": "test_03_azure_sql_transformation_business_rules",
        "name": "Azure SQL Fact Transformation & Business Rules",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "Azure SQL vs Azure SQL",
        "description": "Validates arithmetic for Gross Amount, Discount Amount, Net Sales, Tax Calculation, and Margin %."
    },
    {
        "id": "test_04_azure_sql_fact_vs_regional_view_aggregates",
        "name": "Azure SQL Fact vs Regional Summary View",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "Azure SQL vs Azure SQL",
        "description": "Reconciles intra-database totals between fact_sales and analytical rollup view vw_sales_regional_summary."
    },
    {
        "id": "test_05_azure_sql_fact_vs_snowflake_fact_volume",
        "name": "Azure SQL Fact vs Snowflake Fact Volume",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "Azure SQL vs Snowflake",
        "description": "Asserts exact row count volume parity between Azure SQL fact_sales and Snowflake fact_sales_orders."
    },
    {
        "id": "test_06_azure_sql_fact_vs_snowflake_fact_attributes",
        "name": "Azure SQL vs Snowflake Row-Level Attribute Diff",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "Azure SQL vs Snowflake",
        "description": "Performs primary key join to detect cell-level discrepancies across all measures and attributes."
    },
    {
        "id": "test_07_azure_sql_fact_vs_snowflake_fact_numeric_kpis",
        "name": "Azure SQL vs Snowflake Numeric KPI Aggregates",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "category": "Azure SQL vs Snowflake",
        "description": "Validates Total Revenue, Gross Sales, Net Sales, and Profit Margins within strict 0.01 tolerance."
    },
    {
        "id": "test_08_snowflake_duplicate_business_keys",
        "name": "Snowflake Duplicate Business Keys Check",
        "category": "Target Data Quality",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "description": "Asserts zero duplicate order_id records in Snowflake Star Schema fact table."
    },
    {
        "id": "test_09_snowflake_referential_integrity_orphaned_keys",
        "name": "Snowflake Referential Integrity & Orphan Check",
        "category": "Target Data Quality",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "description": "Asserts all fact foreign keys resolve cleanly to dim_customer, dim_product, and dim_store."
    },
    {
        "id": "test_10_snowflake_null_constraints_mandatory_columns",
        "name": "Snowflake Mandatory Column Null Constraints",
        "category": "Target Data Quality",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "description": "Ensures critical financial measures and primary keys contain zero NULL values."
    },
    {
        "id": "test_11_azure_sql_view_vs_snowflake_analytical_view_parity",
        "name": "Azure SQL Daily View vs Snowflake Daily View",
        "category": "Azure SQL vs Snowflake",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "description": "Cross-database view reconciliation for daily sales rollup analytics."
    },
    {
        "id": "test_12_sales_operational_bounds_and_validity",
        "name": "Snowflake Operational Limits & Value Bounds",
        "category": "Target Data Quality",
        "script": "tests/pytest_framework/test_sales_dw_reconciliation.py",
        "description": "Validates business limits (positive quantities, reasonable discount & margin percentages)."
    }
]


# ====================================================================
# PAGE ROUTES
# ====================================================================

@app.route("/")
def index():
    return render_template("index.html")


# ====================================================================
# CONNECTION SETUP & SCHEMA DISCOVERY APIS
# ====================================================================

@app.route("/api/connections/config", methods=["GET"])
def get_connections_config():
    return jsonify({"status": "success", "config": conn_mgr.get_config()})


@app.route("/api/connections/save", methods=["POST"])
def save_connections_config():
    payload = request.json or {}
    res = conn_mgr.save_config(payload)
    return jsonify(res)


@app.route("/api/connections/test", methods=["POST"])
def test_connection():
    payload = request.json or {}
    system = payload.get("system", "azure_sql")
    cfg = payload.get("config")
    res = conn_mgr.test_connection(system, cfg)
    return jsonify(res)


@app.route("/api/connections/entities", methods=["GET"])
def list_entities():
    system = request.args.get("system", "azure_sql")
    res = conn_mgr.list_entities(system)
    return jsonify(res)


@app.route("/api/connections/columns", methods=["GET"])
def get_columns():
    system = request.args.get("system", "azure_sql")
    entity = request.args.get("entity", "")
    res = conn_mgr.get_columns(system, entity)
    return jsonify(res)


# ====================================================================
# RECONCILIATION & VALIDATION APIS
# ====================================================================

@app.route("/api/reconcile/run", methods=["POST"])
def run_reconciliation():
    try:
        payload = request.json or {}
        res = reconciler.run_reconciliation(payload)
        return jsonify({"status": "success", "results": res})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@app.route("/api/data/seed", methods=["POST"])
def seed_data():
    try:
        payload = request.json or {}
        inject_anomalies = payload.get("inject_anomalies", False)
        setup_all_sales_warehouses(inject_anomalies=inject_anomalies)
        return jsonify({
            "status": "success",
            "message": "Sales Data Warehouse successfully seeded/reloaded!" + (" (Anomalies injected for testing)" if inject_anomalies else "")
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# ====================================================================
# PYTEST AUTOMATED SUITE RUNNER APIS
# ====================================================================

@app.route("/api/pytest/scenarios", methods=["GET"])
def list_pytest_scenarios():
    return jsonify({"status": "success", "scenarios": PYTEST_SCENARIOS})


@app.route("/api/pytest/run", methods=["POST"])
def run_pytest():
    payload = request.json or {}
    scenario_id = payload.get("scenario_id", "all")
    
    cmd = [sys.executable, "-m", "pytest", "tests/pytest_framework/test_sales_dw_reconciliation.py", "-v", "--tb=short"]
    
    if scenario_id and scenario_id != "all":
        cmd.extend(["-k", scenario_id])

    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
        logs = proc.stdout.splitlines()
        exit_code = proc.returncode

        # Parse test results summary
        passed_count = sum(1 for line in logs if " PASSED" in line)
        failed_count = sum(1 for line in logs if " FAILED" in line or " ERROR" in line)
        total_executed = passed_count + failed_count

        run_id = f"PYTEST-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}"
        scenario_meta = next((s for s in PYTEST_SCENARIOS if s["id"] == scenario_id), None)
        scenario_name = scenario_meta["name"] if scenario_meta else scenario_id

        report_summary = {
            "run_id": run_id,
            "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "scenario_id": scenario_id,
            "scenario_name": scenario_name,
            "category": scenario_meta["category"] if scenario_meta else "Pytest",
            "overall_status": "PASSED" if exit_code == 0 and failed_count == 0 else "FAILED",
            "exit_code": exit_code,
            "total_tests": total_executed if total_executed > 0 else (12 if scenario_id == "all" else 1),
            "passed_tests": passed_count,
            "failed_tests": failed_count,
            "pass_rate_pct": round((passed_count / total_executed * 100) if total_executed > 0 else (100.0 if exit_code == 0 else 0.0), 2),
            "logs": logs
        }

        # Save report JSON
        os.makedirs(REPORTS_DIR, exist_ok=True)
        with open(os.path.join(REPORTS_DIR, f"{run_id}_report.json"), "w", encoding="utf-8") as f:
            json.dump(report_summary, f, indent=2)

        return jsonify({
            "status": "success",
            "results": report_summary
        })

    except subprocess.TimeoutExpired:
        return jsonify({"status": "error", "message": "Pytest execution timed out after 60 seconds."}), 500
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


# ====================================================================
# REPORTING & EXPORT APIS
# ====================================================================

@app.route("/api/reports/list", methods=["GET"])
def list_reports():
    reports = []
    if os.path.exists(REPORTS_DIR):
        for f in sorted(os.listdir(REPORTS_DIR), reverse=True):
            if f.endswith((".json", ".html", ".xlsx", ".csv")):
                path = os.path.join(REPORTS_DIR, f)
                reports.append({
                    "filename": f,
                    "size": f"{os.path.getsize(path) / 1024:.1f} KB",
                    "type": f.split(".")[-1].upper(),
                    "timestamp": datetime.datetime.fromtimestamp(os.path.getmtime(path)).strftime("%Y-%m-%d %H:%M:%S")
                })
    return jsonify({"status": "success", "reports": reports})


@app.route("/api/reports/view/<filename>", methods=["GET"])
def view_report_detail(filename):
    file_path = os.path.join(REPORTS_DIR, filename)
    if os.path.exists(file_path):
        if filename.endswith(".json"):
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return jsonify({"status": "success", "data": data})
        else:
            with open(file_path, "r", encoding="utf-8") as f:
                return jsonify({"status": "success", "raw_content": f.read()})
    return jsonify({"status": "error", "message": "Report file not found"}), 404


@app.route("/api/reports/download/<filename>", methods=["GET"])
def download_report(filename):
    return send_from_directory(REPORTS_DIR, filename, as_attachment=True)


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
