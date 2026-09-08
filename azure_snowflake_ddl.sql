-- ====================================================================
-- DATABASE CREATION & DDL SCRIPTS FOR AZURE SQL (SOURCE) & SNOWFLAKE (TARGET)
-- Designed for Young Learners / Junior Data Engineers
-- ====================================================================

/*
====================================================================
PART 1: MICROSOFT AZURE SQL DATABASE DDL (Transactional Source - 3NF)
====================================================================
Azure SQL acts as our OLTP (Online Transaction Processing) system.
Here we define relational tables with primary keys, foreign keys, 
and operational columns.
*/

-- 1. Create Location Master Table
CREATE TABLE plants_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    location_code VARCHAR(50) NOT NULL UNIQUE,
    city VARCHAR(100) NULL,
    region VARCHAR(100) NULL,
    country VARCHAR(100) NULL,
    latitude DECIMAL(9,6) NULL,
    longitude DECIMAL(9,6) NULL
);

-- 2. Create Plants Table
CREATE TABLE manufacturing_plants (
    plant_id INT IDENTITY(1,1) PRIMARY KEY,
    plant_code VARCHAR(50) NOT NULL UNIQUE,
    plant_name VARCHAR(100) NOT NULL,
    location_code VARCHAR(50) FOREIGN KEY REFERENCES plants_location(location_code),
    capacity_level VARCHAR(20) NULL,
    manager_name VARCHAR(100) NULL
);

-- 3. Create Production Lines Table
CREATE TABLE production_lines (
    line_id VARCHAR(50) PRIMARY KEY,
    line_name VARCHAR(100) NOT NULL,
    plant_code VARCHAR(50) FOREIGN KEY REFERENCES manufacturing_plants(plant_code),
    automation_level VARCHAR(50) NULL,
    status VARCHAR(20) DEFAULT 'Active'
);

-- 4. Create Products Table
CREATE TABLE products (
    product_sku VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NULL,
    unit_price DECIMAL(18,2) NOT NULL,
    standard_cost DECIMAL(18,2) NOT NULL
);

-- 5. Create Work Orders Table
CREATE TABLE work_orders (
    work_order_number VARCHAR(50) PRIMARY KEY,
    plant_code VARCHAR(50) FOREIGN KEY REFERENCES manufacturing_plants(plant_code),
    line_id VARCHAR(50) FOREIGN KEY REFERENCES production_lines(line_id),
    product_sku VARCHAR(50) FOREIGN KEY REFERENCES products(product_sku),
    order_date DATE NOT NULL,
    planned_qty DECIMAL(18,2) NOT NULL,
    produced_qty DECIMAL(18,2) NULL,
    good_qty DECIMAL(18,2) NULL,
    scrap_qty DECIMAL(18,2) NULL,
    yield_pct DECIMAL(5,2) NULL,
    order_status VARCHAR(50) NULL
);


/*
====================================================================
PART 2: SNOWFLAKE DATA WAREHOUSE DDL (Target - Star Schema)
====================================================================
Snowflake acts as our OLAP (Online Analytical Processing) system.
Here we define the target Star Schema tables with integer surrogate keys
for lightning-fast analytical queries.
*/

-- 1. Create Dimension: Date
CREATE OR REPLACE TABLE dim_date (
    date_key INT PRIMARY KEY,
    date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day_of_month INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    fiscal_period VARCHAR(20) NOT NULL
);

-- 2. Create Dimension: Location
CREATE OR REPLACE TABLE dim_location (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    location_code VARCHAR(50) NOT NULL UNIQUE,
    city VARCHAR(100),
    region VARCHAR(100),
    country VARCHAR(100),
    latitude NUMBER(9,6),
    longitude NUMBER(9,6)
);

-- 3. Create Dimension: Plant
CREATE OR REPLACE TABLE dim_plant (
    plant_key INT IDENTITY(1,1) PRIMARY KEY,
    plant_code VARCHAR(50) NOT NULL UNIQUE,
    plant_name VARCHAR(100) NOT NULL,
    location_key INT REFERENCES dim_location(location_key),
    capacity_level VARCHAR(20),
    manager_name VARCHAR(100)
);

-- 4. Create Dimension: Production Line
CREATE OR REPLACE TABLE dim_production_line (
    line_key INT IDENTITY(1,1) PRIMARY KEY,
    line_id VARCHAR(50) NOT NULL UNIQUE,
    line_name VARCHAR(100) NOT NULL,
    plant_key INT REFERENCES dim_plant(plant_key),
    automation_level VARCHAR(50),
    status VARCHAR(20)
);

-- 5. Create Dimension: Product
CREATE OR REPLACE TABLE dim_product (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    unit_price NUMBER(18,2),
    standard_cost NUMBER(18,2)
);

-- 6. Create Fact: Work Orders
CREATE OR REPLACE TABLE fact_work_orders (
    work_order_key INT IDENTITY(1,1) PRIMARY KEY,
    work_order_number VARCHAR(50) NOT NULL UNIQUE,
    date_key INT REFERENCES dim_date(date_key),
    plant_key INT REFERENCES dim_plant(plant_key),
    line_key INT REFERENCES dim_production_line(line_key),
    product_key INT REFERENCES dim_product(product_key),
    planned_quantity NUMBER(18,2) NOT NULL,
    produced_quantity NUMBER(18,2),
    good_quantity NUMBER(18,2),
    scrap_quantity NUMBER(18,2),
    yield_percent NUMBER(5,2),
    order_status VARCHAR(50)
);
