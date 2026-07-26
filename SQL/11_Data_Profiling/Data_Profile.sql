-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Data_Profiling.sql
-- Description  : Data Profiling Queries
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- QUERY 1 : Total Row Count
-- ==========================================================

SELECT
    'fact_sales_monthly' AS table_name,
    COUNT(*) AS total_rows
FROM fact_sales_monthly

UNION ALL

SELECT
    'fact_forecast_monthly',
    COUNT(*)
FROM fact_forecast_monthly

UNION ALL

SELECT
    'helper_clean',
    COUNT(*)
FROM helper_clean;



-- ==========================================================
-- QUERY 2 : Distinct Values
-- ==========================================================

SELECT

    COUNT(DISTINCT customer_code) AS total_customers,

    COUNT(DISTINCT product_code) AS total_products,

    COUNT(DISTINCT market) AS total_markets

FROM helper_clean;



-- ==========================================================
-- QUERY 3 : Date Range
-- ==========================================================

SELECT

    MIN(sales_month) AS first_date,

    MAX(sales_month) AS last_date

FROM helper_clean;



-- ==========================================================
-- QUERY 4 : Numeric Statistics
-- ==========================================================

SELECT

    MIN(sold_quantity) AS min_quantity,

    MAX(sold_quantity) AS max_quantity,

    AVG(sold_quantity) AS avg_quantity

FROM helper_clean;



-- ==========================================================
-- QUERY 5 : Missing Values Summary
-- ==========================================================

SELECT

    SUM(customer_code IS NULL) AS customer_null,

    SUM(product_code IS NULL) AS product_null,

    SUM(sold_quantity IS NULL) AS quantity_null

FROM helper_clean;



-- ==========================================================
-- QUERY 6 : Duplicate Record Check
-- ==========================================================

SELECT

    customer_code,
    product_code,
    sales_month,
    COUNT(*) AS duplicate_rows

FROM helper_clean

GROUP BY
    customer_code,
    product_code,
    sales_month

HAVING COUNT(*) > 1;