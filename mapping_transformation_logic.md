# Mapping & Transformation Logic Specification
### Source: Microsoft Azure SQL (OLTP) $\to$ Target: Snowflake Data Warehouse (Star Schema OLAP)

This mapping document details the source-to-target columns, business rules, and transformations required to migrate data from the transactional Azure SQL database to the Snowflake analytical Star Schema.

---

## 1. Dimension Tables mapping

### Table 1: `dim_location` (SCD Type 1)
- **Source Table (Azure SQL)**: `plants_location`
- **Target Table (Snowflake)**: `dim_location`

| Source Column | Target Column | Target Data Type | Transformation & Mapping Logic |
| :--- | :--- | :--- | :--- |
| *None* | `location_key` | `INT` | Auto-incrementing Surrogate Key (Snowflake `IDENTITY(1,1)`). |
| `location_code` | `location_code` | `VARCHAR(50)` | Natural business key. Map directly. |
| `city` | `city` | `VARCHAR(100)` | Map directly. Normalize with `TRIM` and `UPPER` if string matches. |
| `region` | `region` | `VARCHAR(100)` | Map directly. Trim whitespace. |
| `country` | `country` | `VARCHAR(100)` | Map directly. Default to 'Unknown' if NULL. |
| `latitude` | `latitude` | `NUMBER(9,6)` | Map directly. Cast decimal to number. |
| `longitude` | `longitude` | `NUMBER(9,6)` | Map directly. Cast decimal to number. |

---

### Table 2: `dim_plant` (SCD Type 1)
- **Source Table (Azure SQL)**: `manufacturing_plants`
- **Target Table (Snowflake)**: `dim_plant`

| Source Column | Target Column | Target Data Type | Transformation & Mapping Logic |
| :--- | :--- | :--- | :--- |
| *None* | `plant_key` | `INT` | Auto-incrementing Surrogate Key. |
| `plant_code` | `plant_code` | `VARCHAR(50)` | Natural key. Map directly. |
| `plant_name` | `plant_name` | `VARCHAR(100)`| Map directly. |
| `location_code` | `location_key` | `INT` | Lookup `location_key` from `dim_location` where `dim_location.location_code = manufacturing_plants.location_code`. Default to `-1` (Unknown Location) if no match found. |
| `capacity_level`| `capacity_level`| `VARCHAR(20)` | Convert to standard case (e.g. 'high' $\to$ 'High'). |
| `manager_name` | `manager_name` | `VARCHAR(100)`| Map directly. |

---

### Table 3: `dim_production_line` (SCD Type 1)
- **Source Table (Azure SQL)**: `production_lines`
- **Target Table (Snowflake)**: `dim_production_line`

| Source Column | Target Column | Target Data Type | Transformation & Mapping Logic |
| :--- | :--- | :--- | :--- |
| *None* | `line_key` | `INT` | Auto-incrementing Surrogate Key. |
| `line_id` | `line_id` | `VARCHAR(50)` | Natural key. Map directly. |
| `line_name` | `line_name` | `VARCHAR(100)`| Map directly. |
| `plant_code` | `plant_key` | `INT` | Lookup `plant_key` from `dim_plant` where `dim_plant.plant_code = production_lines.plant_code`. Default to `-1` if no match. |
| `automation_level`| `automation_level`| `VARCHAR(50)` | Map directly. |
| `status` | `status` | `VARCHAR(20)` | Map directly. |

---

### Table 4: `dim_product` (SCD Type 1)
- **Source Table (Azure SQL)**: `products`
- **Target Table (Snowflake)**: `dim_product`

| Source Column | Target Column | Target Data Type | Transformation & Mapping Logic |
| :--- | :--- | :--- | :--- |
| *None* | `product_key` | `INT` | Auto-incrementing Surrogate Key. |
| `product_sku` | `product_sku` | `VARCHAR(50)` | Natural key. Map directly. |
| `product_name` | `product_name` | `VARCHAR(200)`| Map directly. |
| `category` | `category` | `VARCHAR(100)`| Map directly. |
| `unit_price` | `unit_price` | `NUMBER(18,2)`| Map directly. Cast numeric to number. |
| `standard_cost` | `standard_cost` | `NUMBER(18,2)`| Map directly. Cast numeric to number. |

---

### Table 5: `dim_date` (Pre-populated)
- **Source Table (Azure SQL)**: *None* (Generated using a calendar dimension script)
- **Target Table (Snowflake)**: `dim_date`

| Column | Data Type | Formula / Logic |
| :--- | :--- | :--- |
| `date_key` | `INT` | Format: `YYYYMMDD` (e.g., `20260827`). |
| `date` | `DATE` | Standard date format `YYYY-MM-DD`. |
| `year` | `INT` | Extract Year: `YEAR(date)`. |
| `quarter` | `INT` | Extract Quarter: `QUARTER(date)`. |
| `month` | `INT` | Extract Month number: `MONTH(date)`. |
| `month_name` | `VARCHAR(20)` | Extract Month Name: `MONTHNAME(date)`. |
| `day_of_month` | `INT` | Extract Day: `DAY(date)`. |
| `day_name` | `VARCHAR(20)` | Extract Day Name: `DAYNAME(date)`. |
| `fiscal_period` | `VARCHAR(20)` | Concatenate: `'FY' || YEAR(date) || '-P' || MONTH(date)`. |

---

## 2. Fact Tables mapping

### Table 6: `fact_work_orders` (Granular Fact)
- **Source Table (Azure SQL)**: `work_orders`
- **Target Table (Snowflake)**: `fact_work_orders`

| Source Column | Target Column | Target Data Type | Transformation & Mapping Logic |
| :--- | :--- | :--- | :--- |
| *None* | `work_order_key` | `INT` | Auto-incrementing Surrogate Key. |
| `work_order_number` | `work_order_number` | `VARCHAR(50)` | Map directly. |
| `order_date` | `date_key` | `INT` | Format date `YYYY-MM-DD` as `YYYYMMDD` integer (e.g. `2026-08-27` $\to$ `20260827`). |
| `plant_code` | `plant_key` | `INT` | Lookup `plant_key` from `dim_plant` where `dim_plant.plant_code = work_orders.plant_code`. Default to `-1` if no match. |
| `line_id` | `line_key` | `INT` | Lookup `line_key` from `dim_production_line` where `dim_production_line.line_id = work_orders.line_id`. Default to `-1` if no match. |
| `product_sku` | `product_key` | `INT` | Lookup `product_key` from `dim_product` where `dim_product.product_sku = work_orders.product_sku`. Default to `-1` if no match. |
| `planned_qty` | `planned_quantity` | `NUMBER(18,2)`| Map directly. |
| `produced_qty` | `produced_quantity`| `NUMBER(18,2)`| Map directly. If negative or invalid, write mismatch record and flag alert. |
| `good_qty` | `good_quantity` | `NUMBER(18,2)`| Map directly. |
| `scrap_qty` | `scrap_quantity`| `NUMBER(18,2)`| Map directly. |
| `yield_pct` | `yield_percent` | `NUMBER(5,2)` | Calculate in transit if NULL: `(good_qty / produced_qty) * 100.0`. Round to 2 decimal places. |
| `order_status` | `order_status` | `VARCHAR(50)` | Map directly. Upper-case code for alignment check. |
