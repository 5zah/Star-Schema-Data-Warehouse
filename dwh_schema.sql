-- ====================================================================
-- MANUFACTURING STAR SCHEMA DATA WAREHOUSE DDL
-- Dimensions: dim_date, dim_location, dim_plant, dim_production_line,
--             dim_product, dim_color, dim_machine, dim_operator,
--             dim_supplier, dim_material, dim_material_sales, dim_defect_catalog
-- Facts:      fact_work_orders, fact_sales_detail, fact_order_detail,
--             fact_machine_telemetry, fact_quality_inspections,
--             fact_labor_performance, fact_cost_financials, fact_procurement
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. DIMENSION TABLES
-- --------------------------------------------------------------------

-- Date Dimension
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INTEGER PRIMARY KEY,           -- YYYYMMDD format (e.g., 20240811)
    full_date DATE NOT NULL UNIQUE,
    calendar_year INTEGER NOT NULL,
    calendar_quarter INTEGER NOT NULL,
    calendar_month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_short_name VARCHAR(3) NOT NULL,
    calendar_week INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend INTEGER NOT NULL DEFAULT 0,
    fiscal_period VARCHAR(10) NOT NULL,    -- e.g. 2024-Q3
    fiscal_year INTEGER NOT NULL,
    fiscal_quarter INTEGER NOT NULL
);

-- Location Dimension (Plants, Warehouses, Customer Destinations, Supplier Origins)
CREATE TABLE IF NOT EXISTS dim_location (
    location_key INTEGER PRIMARY KEY AUTOINCREMENT,
    location_code VARCHAR(50) NOT NULL UNIQUE,
    location_type VARCHAR(50) NOT NULL,     -- 'Plant', 'Warehouse', 'Customer_Destination', 'Supplier_Origin'
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    city VARCHAR(100),
    address_line1 VARCHAR(255),
    postal_code VARCHAR(50),
    timezone VARCHAR(50),
    latitude REAL,
    longitude REAL,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Plant Dimension
CREATE TABLE IF NOT EXISTS dim_plant (
    plant_key INTEGER PRIMARY KEY AUTOINCREMENT,
    plant_code VARCHAR(50) NOT NULL UNIQUE,
    location_key INTEGER,
    plant_name VARCHAR(150) NOT NULL,
    plant_type VARCHAR(100),
    square_footage REAL,
    number_of_employees INTEGER,
    established_year INTEGER,
    iso_9001_certified VARCHAR(10),
    iso_14001_certified VARCHAR(10),
    iatf_16949_certified VARCHAR(10),
    plant_manager VARCHAR(150),
    energy_source_primary VARCHAR(100),
    annual_capacity_units REAL,
    shift_pattern VARCHAR(50),
    union_site_flag VARCHAR(10),
    erp_system VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key)
);

-- Production Line Dimension
CREATE TABLE IF NOT EXISTS dim_production_line (
    line_key INTEGER PRIMARY KEY AUTOINCREMENT,
    line_id VARCHAR(50) NOT NULL UNIQUE,
    plant_key INTEGER NOT NULL,
    line_name VARCHAR(150) NOT NULL,
    line_type VARCHAR(100),
    automation_level VARCHAR(50),
    installed_date DATE,
    number_of_stations INTEGER,
    number_of_machines INTEGER,
    design_capacity_units_per_hour REAL,
    safety_rating VARCHAR(20),
    line_layout_type VARCHAR(50),
    product_family_assigned VARCHAR(100),
    digital_twin_enabled VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plant_key) REFERENCES dim_plant(plant_key)
);

-- Color Dimension (Industrial Finishing, Coatings & Material Colors)
CREATE TABLE IF NOT EXISTS dim_color (
    color_key INTEGER PRIMARY KEY AUTOINCREMENT,
    color_code VARCHAR(50) NOT NULL UNIQUE,
    color_name VARCHAR(100) NOT NULL,
    hex_code VARCHAR(10),
    finish_type VARCHAR(50),               -- 'Matte', 'Gloss', 'Anodized', 'Powder Coated', 'Raw/Brushed'
    ral_code VARCHAR(20),                  -- e.g. RAL 7016, RAL 9005
    pantone_reference VARCHAR(30),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product Dimension
CREATE TABLE IF NOT EXISTS dim_product (
    product_key INTEGER PRIMARY KEY AUTOINCREMENT,
    product_sku VARCHAR(50) NOT NULL UNIQUE,
    product_family VARCHAR(100) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    product_revision VARCHAR(20),
    bom_version VARCHAR(20),
    product_category VARCHAR(100),
    unit_of_measure VARCHAR(20),
    standard_weight_g REAL,
    standard_cost_usd REAL,
    list_price_usd REAL,
    product_status VARCHAR(50),
    material_primary VARCHAR(100),
    target_cpk REAL,
    shelf_life_days INTEGER,
    country_of_origin VARCHAR(100),
    rohs_compliant VARCHAR(10),
    reach_compliant VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Machine Dimension
CREATE TABLE IF NOT EXISTS dim_machine (
    machine_key INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_id VARCHAR(50) NOT NULL UNIQUE,
    line_key INTEGER NOT NULL,
    machine_type VARCHAR(100),
    machine_manufacturer VARCHAR(150),
    machine_model_year INTEGER,
    machine_serial_number VARCHAR(100),
    useful_life_years INTEGER,
    depreciation_method VARCHAR(50),
    plc_firmware_version VARCHAR(50),
    iot_sensor_enabled VARCHAR(10),
    predictive_maintenance_enabled VARCHAR(10),
    criticality_rank VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (line_key) REFERENCES dim_production_line(line_key)
);

-- Operator Dimension
CREATE TABLE IF NOT EXISTS dim_operator (
    operator_key INTEGER PRIMARY KEY AUTOINCREMENT,
    operator_id VARCHAR(50) NOT NULL UNIQUE,
    operator_name VARCHAR(150) NOT NULL,
    department VARCHAR(100),
    job_title VARCHAR(100),
    hire_date DATE,
    years_of_experience REAL,
    operator_certification_level VARCHAR(50),
    shift_assignment VARCHAR(50),
    labor_rate_usd_per_hr REAL,
    union_member_flag VARCHAR(10),
    active_flag VARCHAR(10),
    supervisor_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Supplier Dimension
CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_key INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_id VARCHAR(50) NOT NULL UNIQUE,
    supplier_name VARCHAR(150) NOT NULL,
    supplier_country VARCHAR(100),
    supplier_tier VARCHAR(50),
    relationship_start_date DATE,
    preferred_supplier_flag VARCHAR(10),
    supplier_quality_rating REAL,
    on_time_delivery_rate_percent REAL,
    defect_ppm REAL,
    iso_9001_certified VARCHAR(10),
    iatf_16949_certified VARCHAR(10),
    approved_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Material Dimension
CREATE TABLE IF NOT EXISTS dim_material (
    material_key INTEGER PRIMARY KEY AUTOINCREMENT,
    material_id VARCHAR(50) NOT NULL UNIQUE,
    raw_material_type VARCHAR(100) NOT NULL,
    material_lot_number VARCHAR(50),
    material_batch_number VARCHAR(50),
    supplier_key INTEGER,
    material_unit_cost_usd REAL,
    abc_classification VARCHAR(10),
    hazardous_material_flag VARCHAR(10),
    country_of_origin VARCHAR(100),
    storage_condition_required VARCHAR(100),
    recycled_content_percent REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_key) REFERENCES dim_supplier(supplier_key)
);

-- Material Sales Dimension (for B2B & Raw Material Distribution channels)
CREATE TABLE IF NOT EXISTS dim_material_sales (
    material_sales_key INTEGER PRIMARY KEY AUTOINCREMENT,
    material_sales_code VARCHAR(50) NOT NULL UNIQUE,
    material_key INTEGER NOT NULL,
    sales_category VARCHAR(100) NOT NULL,   -- 'Direct Material', 'Fabricated Stock', 'Secondary Recycled', 'Export Surplus'
    material_grade VARCHAR(50),
    standard_sales_price_usd REAL,
    min_order_quantity_kg REAL,
    target_margin_percent REAL,
    tax_classification_code VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (material_key) REFERENCES dim_material(material_key)
);

-- Defect Catalog Dimension
CREATE TABLE IF NOT EXISTS dim_defect_catalog (
    defect_key INTEGER PRIMARY KEY AUTOINCREMENT,
    defect_code VARCHAR(50) NOT NULL UNIQUE,
    primary_defect_type VARCHAR(100) NOT NULL,
    secondary_defect_type VARCHAR(100),
    critical_defect_flag VARCHAR(10) NOT NULL DEFAULT 'No',
    severity_level VARCHAR(20) DEFAULT 'Medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------------------
-- 2. FACT TABLES (With surrogate Primary Keys and Dimension Foreign Keys)
-- --------------------------------------------------------------------

-- Fact Work Orders / Production Runs
CREATE TABLE IF NOT EXISTS fact_work_orders (
    work_order_key INTEGER PRIMARY KEY AUTOINCREMENT,
    work_order_number VARCHAR(50) NOT NULL UNIQUE,
    order_date_key INTEGER NOT NULL,
    plant_key INTEGER NOT NULL,
    line_key INTEGER NOT NULL,
    product_key INTEGER NOT NULL,
    color_key INTEGER NOT NULL,
    production_order_type VARCHAR(50),
    shift VARCHAR(50),
    order_status VARCHAR(50),
    planned_quantity REAL,
    produced_quantity REAL,
    good_quantity REAL,
    scrap_quantity REAL,
    rework_quantity REAL,
    yield_percent REAL,
    scrap_rate_percent REAL,
    cycle_time_sec REAL,
    takt_time_sec REAL,
    setup_time_min REAL,
    total_runtime_hours REAL,
    total_downtime_hours REAL,
    oee_percent REAL,
    availability_percent REAL,
    performance_percent REAL,
    quality_rate_percent REAL,
    customer_order_number VARCHAR(50),
    customer_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (plant_key) REFERENCES dim_plant(plant_key),
    FOREIGN KEY (line_key) REFERENCES dim_production_line(line_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (color_key) REFERENCES dim_color(color_key)
);

-- Fact Sales Detail
CREATE TABLE IF NOT EXISTS fact_sales_detail (
    sales_detail_key INTEGER PRIMARY KEY AUTOINCREMENT,
    sales_invoice_number VARCHAR(50) NOT NULL,
    invoice_line_number INTEGER NOT NULL DEFAULT 1,
    sale_date_key INTEGER NOT NULL,
    ship_date_key INTEGER,
    product_key INTEGER NOT NULL,
    color_key INTEGER NOT NULL,
    location_key INTEGER NOT NULL,          -- Destination location
    plant_key INTEGER NOT NULL,             -- Fulfillment plant
    material_sales_key INTEGER,
    customer_order_number VARCHAR(50),
    customer_name VARCHAR(150),
    customer_po_number VARCHAR(50),
    sales_quantity REAL NOT NULL,
    unit_selling_price_usd REAL NOT NULL,
    gross_sales_amount_usd REAL NOT NULL,
    discount_amount_usd REAL DEFAULT 0,
    net_sales_amount_usd REAL NOT NULL,
    cost_of_goods_sold_usd REAL NOT NULL,
    gross_profit_usd REAL NOT NULL,
    gross_margin_percent REAL,
    tax_amount_usd REAL DEFAULT 0,
    freight_charge_usd REAL DEFAULT 0,
    carrier VARCHAR(100),
    tracking_number VARCHAR(100),
    on_time_delivery_flag VARCHAR(10),
    return_flag VARCHAR(10) DEFAULT 'No',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sale_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (ship_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (color_key) REFERENCES dim_color(color_key),
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key),
    FOREIGN KEY (plant_key) REFERENCES dim_plant(plant_key),
    FOREIGN KEY (material_sales_key) REFERENCES dim_material_sales(material_sales_key),
    UNIQUE (sales_invoice_number, invoice_line_number)
);

-- Fact Order Detail (Customer & Work Order line-item tracking)
CREATE TABLE IF NOT EXISTS fact_order_detail (
    order_detail_key INTEGER PRIMARY KEY AUTOINCREMENT,
    order_number VARCHAR(50) NOT NULL,
    order_line_item INTEGER NOT NULL,
    order_date_key INTEGER NOT NULL,
    requested_date_key INTEGER,
    product_key INTEGER NOT NULL,
    color_key INTEGER NOT NULL,
    location_key INTEGER NOT NULL,
    line_key INTEGER,
    material_key INTEGER,
    order_type VARCHAR(50),
    order_quantity REAL NOT NULL,
    fulfilled_quantity REAL NOT NULL,
    backorder_quantity REAL DEFAULT 0,
    unit_price_usd REAL NOT NULL,
    line_total_usd REAL NOT NULL,
    lead_time_days REAL,
    order_status VARCHAR(50),
    on_time_delivery_flag VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (requested_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (color_key) REFERENCES dim_color(color_key),
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key),
    FOREIGN KEY (line_key) REFERENCES dim_production_line(line_key),
    FOREIGN KEY (material_key) REFERENCES dim_material(material_key),
    UNIQUE (order_number, order_line_item)
);

-- Fact Machine Telemetry Readings
CREATE TABLE IF NOT EXISTS fact_machine_telemetry (
    telemetry_key INTEGER PRIMARY KEY AUTOINCREMENT,
    reading_id VARCHAR(50) NOT NULL UNIQUE,
    reading_date_key INTEGER NOT NULL,
    machine_key INTEGER NOT NULL,
    work_order_key INTEGER,
    reading_timestamp TIMESTAMP NOT NULL,
    spindle_speed_rpm REAL,
    feed_rate_mm_min REAL,
    tool_wear_percent REAL,
    tool_changes_count INTEGER,
    coolant_flow_l_min REAL,
    hydraulic_pressure_bar REAL,
    pneumatic_pressure_bar REAL,
    motor_temperature_c REAL,
    ambient_temperature_c REAL,
    ambient_humidity_percent REAL,
    vibration_mm_s REAL,
    noise_level_db REAL,
    power_consumption_kwh REAL,
    voltage_v REAL,
    current_a REAL,
    robot_cycle_count INTEGER,
    robot_error_count INTEGER,
    data_quality_score REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reading_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (machine_key) REFERENCES dim_machine(machine_key),
    FOREIGN KEY (work_order_key) REFERENCES fact_work_orders(work_order_key)
);

-- Fact Quality Inspections & Measurements
CREATE TABLE IF NOT EXISTS fact_quality_inspections (
    quality_fact_key INTEGER PRIMARY KEY AUTOINCREMENT,
    inspection_id VARCHAR(50) NOT NULL UNIQUE,
    inspection_date_key INTEGER NOT NULL,
    work_order_key INTEGER,
    product_key INTEGER NOT NULL,
    defect_key INTEGER NOT NULL,
    color_key INTEGER NOT NULL,
    qc_result VARCHAR(50) NOT NULL,
    defect_count INTEGER DEFAULT 0,
    sample_size INTEGER,
    dimension_1_nominal_mm REAL,
    dimension_1_actual_mm REAL,
    dimension_1_tolerance_mm REAL,
    dimension_2_nominal_mm REAL,
    dimension_2_actual_mm REAL,
    dimension_2_tolerance_mm REAL,
    weight_nominal_g REAL,
    weight_actual_g REAL,
    hardness_hrc REAL,
    tensile_strength_mpa REAL,
    spc_cpk REAL,
    spc_ppk REAL,
    inspection_duration_min REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inspection_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (work_order_key) REFERENCES fact_work_orders(work_order_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (defect_key) REFERENCES dim_defect_catalog(defect_key),
    FOREIGN KEY (color_key) REFERENCES dim_color(color_key)
);

-- Fact Labor Performance
CREATE TABLE IF NOT EXISTS fact_labor_performance (
    labor_fact_key INTEGER PRIMARY KEY AUTOINCREMENT,
    labor_id VARCHAR(50) NOT NULL UNIQUE,
    work_date_key INTEGER NOT NULL,
    operator_key INTEGER NOT NULL,
    work_order_key INTEGER,
    hours_worked REAL NOT NULL,
    overtime_hours REAL DEFAULT 0,
    labor_rate_usd_per_hr REAL,
    total_labor_cost_usd REAL,
    ppe_compliance_percent REAL,
    standard_labor_hours REAL,
    labor_efficiency_percent REAL,
    safety_incident_flag VARCHAR(10),
    near_miss_flag VARCHAR(10),
    absenteeism_flag VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (work_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (operator_key) REFERENCES dim_operator(operator_key),
    FOREIGN KEY (work_order_key) REFERENCES fact_work_orders(work_order_key)
);

-- Fact Cost & Financials
CREATE TABLE IF NOT EXISTS fact_cost_financials (
    cost_fact_key INTEGER PRIMARY KEY AUTOINCREMENT,
    cost_id VARCHAR(50) NOT NULL UNIQUE,
    fiscal_date_key INTEGER NOT NULL,
    work_order_key INTEGER,
    material_cost_usd REAL,
    labor_cost_usd REAL,
    overhead_cost_usd REAL,
    tooling_cost_usd REAL,
    energy_cost_usd REAL,
    total_unit_cost_usd REAL,
    standard_cost_usd REAL,
    cost_variance_usd REAL,
    scrap_cost_usd REAL,
    selling_price_usd REAL,
    gross_margin_percent REAL,
    budget_variance_percent REAL,
    freight_cost_usd REAL,
    customs_duty_usd REAL,
    warranty_cost_usd REAL,
    roi_percent REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fiscal_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (work_order_key) REFERENCES fact_work_orders(work_order_key)
);

-- Fact Procurement (Purchase Orders)
CREATE TABLE IF NOT EXISTS fact_procurement (
    procurement_key INTEGER PRIMARY KEY AUTOINCREMENT,
    po_number VARCHAR(50) NOT NULL,
    po_line_item INTEGER NOT NULL,
    order_date_key INTEGER NOT NULL,
    delivery_date_key INTEGER,
    supplier_key INTEGER NOT NULL,
    material_key INTEGER NOT NULL,
    order_quantity_kg REAL NOT NULL,
    unit_price_usd REAL NOT NULL,
    total_po_value_usd REAL NOT NULL,
    lead_time_days REAL,
    freight_cost_usd REAL,
    customs_duty_usd REAL,
    on_time_delivery_flag VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (delivery_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (supplier_key) REFERENCES dim_supplier(supplier_key),
    FOREIGN KEY (material_key) REFERENCES dim_material(material_key),
    UNIQUE (po_number, po_line_item)
);

-- --------------------------------------------------------------------
-- 3. PERFORMANCE INDEXES
-- --------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_fwo_date ON fact_work_orders(order_date_key);
CREATE INDEX IF NOT EXISTS idx_fwo_plant ON fact_work_orders(plant_key);
CREATE INDEX IF NOT EXISTS idx_fwo_line ON fact_work_orders(line_key);
CREATE INDEX IF NOT EXISTS idx_fwo_product ON fact_work_orders(product_key);

CREATE INDEX IF NOT EXISTS idx_fsales_date ON fact_sales_detail(sale_date_key);
CREATE INDEX IF NOT EXISTS idx_fsales_prod ON fact_sales_detail(product_key);
CREATE INDEX IF NOT EXISTS idx_fsales_loc ON fact_sales_detail(location_key);
CREATE INDEX IF NOT EXISTS idx_fsales_plant ON fact_sales_detail(plant_key);

CREATE INDEX IF NOT EXISTS idx_ford_date ON fact_order_detail(order_date_key);
CREATE INDEX IF NOT EXISTS idx_ford_prod ON fact_order_detail(product_key);

CREATE INDEX IF NOT EXISTS idx_fmch_date ON fact_machine_telemetry(reading_date_key);
CREATE INDEX IF NOT EXISTS idx_fmch_mch ON fact_machine_telemetry(machine_key);

CREATE INDEX IF NOT EXISTS idx_fqc_date ON fact_quality_inspections(inspection_date_key);
CREATE INDEX IF NOT EXISTS idx_fqc_prod ON fact_quality_inspections(product_key);

CREATE INDEX IF NOT EXISTS idx_flab_date ON fact_labor_performance(work_date_key);
CREATE INDEX IF NOT EXISTS idx_flab_opr ON fact_labor_performance(operator_key);

CREATE INDEX IF NOT EXISTS idx_fcost_date ON fact_cost_financials(fiscal_date_key);
CREATE INDEX IF NOT EXISTS idx_fproc_date ON fact_procurement(order_date_key);
