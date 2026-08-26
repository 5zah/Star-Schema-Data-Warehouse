# 🏭 Enterprise ETL Testing, Data Warehouse Migration & Multi-Database Reconciliation Framework

A production-grade **Manufacturing Data Warehouse (Star Schema)**, **Data Scaling Synthesizer**, **Warehouse Migration Pipeline**, and **Reusable Multi-Database Reconciliation Engine** with automated reporting across all 4 validation scopes.

---

## 🌟 Key Features

1. **Star Schema Data Warehouse (`data/manufacturing_dwh.db`)**:
   - **12 Conformed Dimensions**: `dim_date`, `dim_location`, `dim_color`, `dim_plant`, `dim_production_line`, `dim_product`, `dim_machine`, `dim_operator`, `dim_supplier`, `dim_material`, `dim_material_sales`, `dim_defect_catalog`.
   - **8 Granular Fact Tables**: `fact_work_orders`, `fact_sales_detail`, `fact_order_detail`, `fact_machine_telemetry`, `fact_quality_inspections`, `fact_labor_performance`, `fact_cost_financials`, `fact_procurement`.
   - Explicit Primary Keys (`_key`), Foreign Keys (`_key`), and performance B-Tree indexes.

2. **Generic Multi-Database Reconciliation Engine (`src/reconciliation/`)**:
   - **Multi-Database Support**: Connects to SQLite, DuckDB, PostgreSQL, MySQL, SQL Server, Snowflake, Oracle, Excel, and CSV via unified SQLAlchemy abstraction.
   - **Dynamic Mappings**: Configurable YAML/JSON mapping rules & automated schema mapping inference.
   - **4-Pillar Validation Scope**:
     - *Scope 1: Data Volume Reconciliation* (Row counts, partition breakdowns, missing key detection).
     - *Scope 2: Attribute-Level Validation* (100% cell-by-cell comparison, floating-point `atol`/`rtol` tolerances, string normalization, date parsing).
     - *Scope 3: Aggregate Measure Reconciliation* (`SUM`, `AVG`, `MIN`, `MAX`, `STDDEV`, `COUNT` across dimensions).
     - *Scope 4: Multi-Source Consistency Assessment* (Cross-validating Flat Excel vs Relational vs Star Schema DWH).

3. **Data Scaling Synthesizer (`src/scaling/`)**:
   - Scales manufacturing data (from 1k to 10k, 100k, 1M+ rows) while maintaining 100% referential integrity across all foreign keys.

4. **Automated Enterprise Reporting (`reports/`)**:
   - **Interactive HTML Dashboard**: Glassmorphism UI with Chart.js charts and filterable mismatch tables.
   - **Formatted Multi-Tab Excel Workbook**: Formatted tabs for Executive Summary, Volume, Attribute, Aggregates, and Multi-Source.
   - **Executive Markdown Summary**: Clean scorecards for CI/CD and PRs.
   - **Machine-Readable JSON**: Complete validation output for automated build gates.

---

## 🚀 Quick Start Guide

### 1. Run Complete End-to-End Pipeline
Executes Migration $\to$ 5x Data Scaling $\to$ Full Reconciliation $\to$ Anomaly Verification Test:
```bash
python main.py --action all
```

### 2. Run Individual Actions
```bash
# Run only Data Warehouse Migration
python main.py --action migrate

# Scale test dataset by 10x multiplier
python main.py --action scale --multiplier 10

# Run Multi-Database Reconciliation Engine
python main.py --action reconcile

# Run Controlled Anomaly Injection & Detection Test
python main.py --action test-anomaly

# Run Automated Unit & Integration Tests
python -m unittest discover -s tests
```

---

## 📁 Repository Structure

```
ETL testing/
├── config/
│   ├── dwh_schema.sql                  # Star schema DDL (12 Dims, 8 Facts, Indexes)
│   ├── reconciliation_config.yaml      # Dynamic mappings & reconciliation test suites
│   └── scale_config.yaml               # Scaling configuration
├── src/
│   ├── connectors/                     # Multi-DB & File connector layer
│   │   ├── base.py                     # Abstract Base Connector
│   │   ├── sqlalchemy_connector.py     # SQLAlchemy Multi-DB Connector
│   │   ├── excel_connector.py          # Excel Workbook / Sheet Connector
│   │   ├── csv_connector.py            # CSV / Parquet Connector
│   │   └── factory.py                  # Connector Factory
│   ├── warehouse/                      # DWH Migration & Modeling
│   │   ├── schema_builder.py           # DDL Executor & Index Manager
│   │   ├── transformer.py              # Dimensional Lookups & Fact Grain Builder
│   │   └── migration_pipeline.py       # Full ETL Migration Orchestrator
│   ├── scaling/                        # Data Scaling Synthesizer
│   │   └── data_scaler.py              # Referential Integrity Scaler
│   ├── reconciliation/                 # Reusable Reconciliation Engine
│   │   ├── engine.py                   # Master Test Suite Orchestrator
│   │   ├── mapper.py                   # Dynamic Mapper & Schema Parser
│   │   ├── volume_validator.py         # Scope 1: Volume & Partition Validator
│   │   ├── attribute_validator.py      # Scope 2: Attribute & Cell Validator
│   │   ├── aggregate_validator.py      # Scope 3: Aggregate Measure Validator
│   │   └── multi_source_validator.py   # Scope 4: Multi-Source Consistency Validator
│   ├── reporting/                      # Enterprise Reporting Engine
│   │   ├── html_reporter.py            # Interactive HTML Dashboard
│   │   ├── excel_reporter.py           # Multi-Tab Styled Excel Workbook
│   │   └── markdown_reporter.py        # Executive Summary
│   └── cli.py                          # Unified CLI Entry Point
├── tests/
│   └── test_reconciliation.py          # Automated Unit & Integration Test Suite
├── reports/                            # Generated HTML, Excel, MD, JSON Reports
├── data/                               # Generated SQLite DWH & Scaled Databases
├── main.py                             # Project Root Entry Point
└── README.md
```

---

## 📊 Verification & Test Results
- **Production Baseline Reconciliation**: **100.0% Pass (25 of 25 Test Suites Passed)** with **38,000 / 38,000 Cells Matched (100.00% accuracy)**.
- **Unit & Integration Suite**: **7 of 7 Tests Passed** (`Ran 7 tests in 32.9s - OK`).
- **Anomaly Detection Test**: Verified 100% detection of dropped records, numeric attribute corruption, and string attribute corruption with zero false negatives.
