-- ====================================================================
-- E2E SQL VALIDATION SCRIPTS FOR ETL TESTING (AZURE SQL TO SNOWFLAKE)
-- Designed for Young Learners / Junior QA Engineers
-- ====================================================================

/*
====================================================================
1. DATA VOLUME RECONCILIATION
====================================================================
Check if row counts match between Source (Azure SQL) and Target (Snowflake)
*/

-- [QUERY 1.1] Work Orders Row Count
-- Run on Azure SQL:
SELECT COUNT(*) AS Source_Count FROM work_orders;

-- Run on Snowflake:
SELECT COUNT(*) AS Target_Count FROM fact_work_orders;

-- [QUERY 1.2] Row Count Reconciliation by Group / Partition (e.g. by Plant)
-- Run on Azure SQL:
SELECT plant_code, COUNT(*) AS Source_Count 
FROM work_orders 
GROUP BY plant_code 
ORDER BY plant_code;

-- Run on Snowflake:
SELECT p.plant_code, COUNT(f.work_order_number) AS Target_Count 
FROM fact_work_orders f
JOIN dim_plant p ON f.plant_key = p.plant_key
GROUP BY p.plant_code 
ORDER BY p.plant_code;


/*
====================================================================
2. DUPLICATE AND UNIQUE KEY CHECKS
====================================================================
Verify that primary keys are unique and check if there are duplicate records.
*/

-- [QUERY 2.1] Check for Duplicate Business Keys in Target Fact Table
-- Run on Snowflake:
SELECT work_order_number, COUNT(*) AS Duplicate_Count
FROM fact_work_orders
GROUP BY work_order_number
HAVING COUNT(*) > 1;

-- [QUERY 2.2] Check for Nulls in Primary and Foreign Keys
-- Run on Snowflake:
SELECT 
    SUM(CASE WHEN work_order_key IS NULL THEN 1 ELSE 0 END) AS Null_PK_Count,
    SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) AS Null_Date_FK_Count,
    SUM(CASE WHEN plant_key IS NULL THEN 1 ELSE 0 END) AS Null_Plant_FK_Count,
    SUM(CASE WHEN line_key IS NULL THEN 1 ELSE 0 END) AS Null_Line_FK_Count,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS Null_Product_FK_Count
FROM fact_work_orders;


/*
====================================================================
3. AGGREGATE MEASURE RECONCILIATION
====================================================================
Validate SUM, AVG, and percentage metrics between Source and Target.
*/

-- [QUERY 3.1] Global Sums and Averages
-- Run on Azure SQL:
SELECT 
    SUM(planned_qty) AS Total_Planned,
    SUM(produced_qty) AS Total_Produced,
    SUM(good_qty) AS Total_Good,
    SUM(scrap_qty) AS Total_Scrap,
    AVG(yield_pct) AS Avg_Yield
FROM work_orders;

-- Run on Snowflake:
SELECT 
    SUM(planned_quantity) AS Total_Planned,
    SUM(produced_quantity) AS Total_Produced,
    SUM(good_quantity) AS Total_Good,
    SUM(scrap_quantity) AS Total_Scrap,
    AVG(yield_percent) AS Avg_Yield
FROM fact_work_orders;


/*
====================================================================
4. ATTRIBUTE-LEVEL DATA VALIDATION & MISMATCHES
====================================================================
Check if specific fields are modified or corrupted during migration.
*/

-- [QUERY 4.1] Find Discrepancies in Yield Calculations
-- Run on Snowflake:
SELECT 
    work_order_number, 
    good_quantity, 
    produced_quantity, 
    yield_percent,
    ROUND((good_quantity / NULLIF(produced_quantity, 0)) * 100.0, 2) AS Calculated_Yield,
    ABS(yield_percent - ROUND((good_quantity / NULLIF(produced_quantity, 0)) * 100.0, 2)) AS Yield_Diff
FROM fact_work_orders
WHERE ABS(yield_percent - ROUND((good_quantity / NULLIF(produced_quantity, 0)) * 100.0, 2)) > 0.05;


/*
====================================================================
5. ORPHANED RECORDS & INTEGRITY CHECKS
====================================================================
Verify that all foreign keys link to valid rows in dimensions.
*/

-- [QUERY 5.1] Find Orphaned Work Orders pointing to invalid Plants
-- Run on Snowflake:
SELECT f.work_order_number, f.plant_key
FROM fact_work_orders f
LEFT JOIN dim_plant p ON f.plant_key = p.plant_key
WHERE p.plant_key IS NULL;
