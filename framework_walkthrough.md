# 🏭 Manufacturing ETL Testing & Automation Framework Walkthrough
### A Comprehensive Guide for Quality Assurance & Data Engineers

Welcome to the **Manufacturing ETL Testing and Automation Framework**. This guide provides an in-depth walkthrough of the system architecture, file-by-file inventory, reconciliation logic, and execution methods.

---

## 1. 🌟 System Purpose: What is this framework?

This framework is an **Enterprise-Grade ETL Testing Pipeline and Multi-Database Data Quality Reconciliation Engine**. It delivers:

1. **Transactional to Analytical Migration**: Ingests transactional 3NF sources (Azure SQL / Relational Excel) and transforms them into an optimized Star Schema Data Warehouse (Snowflake / SQLite).
2. **Dynamic Data Scaling Synthesizer**: Synthesizes and scales relational test datasets (from 1k to 10k, 100k, 1M+ rows) while maintaining 100% referential integrity across all surrogate keys and foreign keys.
3. **4-Pillar Multi-Database Reconciliation Engine**:
   - **Scope 1: Data Volume Reconciliation**: Row count comparison, partition/group-level volume validation, missing business key detection.
   - **Scope 2: Attribute-Level Validation**: 100% cell-by-cell comparison with configurable floating-point tolerances (`atol`/`rtol`), string normalization, and date parsing.
   - **Scope 3: Aggregate Measure Reconciliation**: Mathematical audits (`SUM`, `AVG`, `MIN`, `MAX`, `STDDEV`, `COUNT`) with user-defined percentage drift tolerances.
   - **Scope 4: Multi-Source Consistency Assessment**: Cross-verifies flat spreadsheets, relational source tables, and analytical Star Schema facts.
4. **Interactive Dashboard & Automated Mismatch Reporting**:
   - Real-time Flask Web Dashboard with pass/fail gauges and execution logs.
   - Downloadable Excel, HTML, and Markdown mismatch reports highlighting failed cells and root causes.
5. **Dual Testing Framework**:
   - **`pytest` Suite**: SQL-level assertions and negative testing (null checks, duplicate keys, orphaned foreign keys, out-of-bounds manufacturing limits).
   - **`unittest` Suite**: 14 automated test suites (7 baseline PASS tests + 7 injected anomaly FAIL tests).

---

## 2. 📂 Project Structure & Complete File Inventory

```
ETL testing/
├── config/
│   ├── anomaly_test_config.yaml         # Configuration for deliberate defect injection & detection
│   ├── azure_snowflake_ddl.sql          # Azure SQL (Source OLTP) & Snowflake (Target OLAP) DDL
│   ├── dwh_schema.sql                   # SQLite Star Schema schema (12 Dims, 8 Facts, B-Tree Indexes)
│   ├── e2e_sql_validations.sql          # SQL scripts for Volume, Duplicate, Aggregate & Orphan validation
│   ├── mapping_transformation_logic.md  # Source-to-target business rules & transformation logic
│   ├── reconciliation_config.yaml       # Master reconciliation mapping & tolerance rules
│   └── scale_config.yaml                # Multiplier configs for data scaling & volume testing
├── data/
│   ├── manufacturing_dwh.db             # Target SQLite Star Schema Data Warehouse
│   ├── scaled_manufacturing_dwh.db      # Scaled database for load testing
│   └── test_fail_dwh.db                 # Corrupted clone database used for anomaly testing
├── reports/
│   ├── Reconciliation_Report.html       # Interactive Glassmorphism HTML dashboard report
│   ├── Reconciliation_Report.xlsx       # Multi-tab styled Excel mismatch workbook
│   ├── Reconciliation_Summary.md        # Executive markdown scorecard
│   └── reconciliation_results.json      # Machine-readable JSON output for CI/CD gates
├── src/
│   ├── connectors/                      # Database & File Abstraction Layer
│   │   ├── base.py                      # Abstract Base Connector interface
│   │   ├── sqlalchemy_connector.py      # Unified driver for Snowflake, Azure SQL, SQLite, Postgres
│   │   ├── excel_connector.py           # Multi-sheet Excel workbook parser
│   │   ├── csv_connector.py             # CSV / TSV / Parquet connector
│   │   └── factory.py                   # Connector instantiation factory
│   ├── warehouse/                       # ETL Transformation & Migration
│   │   ├── schema_builder.py            # Executes DDL, builds tables & B-Tree performance indexes
│   │   ├── transformer.py               # Surrogate key lookups, date keys & fact table assembly
│   │   └── migration_pipeline.py        # Master ETL orchestrator (Source -> Staging -> DWH)
│   ├── scaling/                         # Test Data Synthesizer
│   │   └── data_scaler.py               # Scaler preserving relational integrity
│   ├── reconciliation/                  # 4-Pillar Validation Engine
│   │   ├── engine.py                    # Master reconciliation test suite runner
│   │   ├── mapper.py                    # YAML configuration & schema mapping parser
│   │   ├── volume_validator.py          # Scope 1: Row count & key audit
│   │   ├── attribute_validator.py       # Scope 2: 100% cell value comparison with tolerances
│   │   ├── aggregate_validator.py       # Scope 3: Mathematical measure audits
│   │   └── multi_source_validator.py    # Scope 4: Multi-source & business rule validator
│   ├── reporting/                       # Multi-Format Report Generators
│   │   ├── html_reporter.py             # Builds interactive HTML report with Chart.js
│   │   ├── excel_reporter.py            # Builds multi-tab formatted Excel mismatch report
│   │   └── markdown_reporter.py         # Builds clean Markdown summary
│   ├── web/                             # Web Application Layer
│   │   ├── app.py                       # Flask server & REST API endpoints
│   │   └── templates/
│   │       └── index.html               # Responsive web UI for triggering actions & downloading reports
│   └── cli.py                           # Command-Line Interface router
├── tests/
│   ├── pytest_framework/                # Pytest Test Framework (Azure SQL / Snowflake / SQLite)
│   │   ├── conftest.py                  # Database connection fixtures & environment variable resolution
│   │   └── test_dwh_reconciliation.py   # SQL-based Positive & Negative test scenarios
│   └── test_reconciliation.py           # 14 Unittest suites (7 PASS + 7 FAIL anomaly detection)
├── isd.md                               # Integration Specification Document (ISD)
├── test_cases.md                        # Formal Test Case Matrix & Specifications
├── setup_guide.md                       # Step-by-Step Onboarding Guide for any laptop
├── framework_walkthrough.md             # This comprehensive architecture & code walkthrough
├── download_package.md                  # Packaging and distribution guide
├── main.py                              # Master CLI execution entry point
├── requirements.txt                     # Python package dependencies
└── README.md                            # High-level project summary
```

---

## 3. 🔍 Detailed Component & File Description

### ⚙️ Configuration Layer (`config/`)
- **`azure_snowflake_ddl.sql`**: Production DDL creating 3NF transactional source tables on Azure SQL and Star Schema analytical tables on Snowflake (with `IDENTITY(1,1)` surrogate keys and constraints).
- **`dwh_schema.sql`**: SQLite DDL creating 12 Dimensions and 8 Facts with composite unique constraints and index optimizations for local development.
- **`e2e_sql_validations.sql`**: End-to-end SQL verification queries for volume reconciliation, duplicate checks, null checks, aggregate validation, and orphan foreign key checks.
- **`mapping_transformation_logic.md`**: Source-to-target data dictionary detailing lookup rules, SCD Type 1 logic, data type conversions, and handling of missing keys.
- **`reconciliation_config.yaml`**: Mapping configurations, primary key specifications, column comparisons, and floating-point tolerances (`atol: 0.01`).
- **`anomaly_test_config.yaml`**: Configures reconciliation tests specifically targeted at catching injected corruptions in the clone database.
- **`scale_config.yaml`**: Multipliers and distribution parameters for synthesizing scaled datasets.

### 🔌 Connector Layer (`src/connectors/`)
- **`base.py`**: Defines abstract `BaseConnector` requiring `connect()`, `disconnect()`, `fetch_dataframe()`, and `get_row_count()`.
- **`sqlalchemy_connector.py`**: Universal SQL driver leveraging SQLAlchemy to connect seamlessly to Azure SQL, Snowflake, Postgres, SQLite, or MySQL.
- **`excel_connector.py`**: Reads multi-tab Excel workbooks into pandas DataFrames.
- **`csv_connector.py`**: Reads CSV, TSV, or Parquet files from directory structures.
- **`factory.py`**: Dynamic factory resolving connector instances from YAML configuration strings.

### 🏭 Warehouse Migration Layer (`src/warehouse/`)
- **`schema_builder.py`**: Reads DDL scripts, drops existing tables, creates schemas, and builds indexes.
- **`transformer.py`**: Performs ETL transformations: generates `date_key` (YYYYMMDD), resolves surrogate foreign key lookups against dimension dictionaries, and calculates derived metrics (e.g. `yield_percent`).
- **`migration_pipeline.py`**: Executes the end-to-end migration pipeline: reads source sheets, transforms dimensions, populates facts, and writes to target database.

### 📈 Data Scaling Synthesizer (`src/scaling/`)
- **`data_scaler.py`**: Generates synthetic transactional records scaled by arbitrary factors (e.g. 5x, 10x, 100x) while preserving referential integrity with dimension tables.

### 🔍 4-Pillar Reconciliation Layer (`src/reconciliation/`)
- **`volume_validator.py`**: Compares total row counts, detects missing business keys in target, and performs partitioned volume checks (e.g. per plant).
- **`attribute_validator.py`**: Merges source and target datasets on primary keys, iterates through all columns, applies numerical tolerances (`atol`/`rtol`), normalizes strings/dates, and records every mismatch.
- **`aggregate_validator.py`**: Calculates mathematical aggregates (`SUM`, `AVG`, `MIN`, `MAX`, `STDDEV`, `COUNT`) across specified dimensions and computes percentage drift against tolerance limits.
- **`multi_source_validator.py`**: Cross-validates metrics across disparate systems (e.g. verifying `produced_quantity == good_quantity + scrap_quantity + rework_quantity`).
- **`engine.py`**: Master test runner parsing YAML test suites, invoking validators, and consolidating validation results into structured payloads.

### 📊 Reporting Layer (`src/reporting/`)
- **`html_reporter.py`**: Generates a self-contained HTML dashboard with glassmorphism design, pass/fail status cards, and filterable mismatch tables.
- **`excel_reporter.py`**: Generates an Excel workbook with styled tabs for Executive Summary, Volume Validation, Attribute Mismatches, Aggregates, and Multi-Source.
- **`markdown_reporter.py`**: Generates a clean Markdown summary table suitable for pull requests and CI/CD summaries.

### 🌐 Web Dashboard Layer (`src/web/`)
- **`app.py`**: Flask web server exposing endpoints for `/api/run-migration`, `/api/run-reconciliation`, `/api/run-anomaly-test`, and `/download-report/<format>`.
- **`templates/index.html`**: Interactive web UI featuring action buttons, execution logs, and direct download links for HTML and Excel mismatch reports.

### 🧪 Test Framework Layer (`tests/`)
- **`pytest_framework/conftest.py`**: Pytest fixtures providing database connections (`azure_sql_engine`, `snowflake_engine`, or SQLite fallback).
- **`pytest_framework/test_dwh_reconciliation.py`**: SQL-driven test cases covering positive reconciliation and negative anomaly detection.
- **`test_reconciliation.py`**: 14 automated unit/integration tests (7 PASS + 7 FAIL) validating the reconciliation engine's ability to verify clean data and catch defects.

---

## 4. 🚀 How to Execute the Framework

### A. Run Full Pipeline via CLI
```bash
# Execute Migration -> Scaling -> Reconciliation -> Anomaly Test
python main.py --action all
```

### B. Run Individual Actions
```bash
# 1. Run Data Warehouse Migration
python main.py --action migrate

# 2. Run Data Scaling (e.g., 5x multiplier)
python main.py --action scale --multiplier 5

# 3. Run Master Reconciliation (Clean baseline)
python main.py --action reconcile

# 4. Run Anomaly Injection & Detection Test
python main.py --action test-anomaly
```

### C. Run Test Suites
```bash
# Run 14 Unittest Test Suites (7 PASS + 7 FAIL)
python -m unittest tests/test_reconciliation.py -v

# Run Pytest Validation Suite
pytest tests/pytest_framework/test_dwh_reconciliation.py -v
```

### D. Run Interactive Web Dashboard
```bash
# Start Flask Server
python src/web/app.py
```
Open your browser at `http://127.0.0.1:5000` to execute tasks and download mismatch reports directly.
