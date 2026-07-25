-- ==========================================================
-- Project : End-to-End Data Engineering & Business Intelligence
-- File    : Dimension_Tables.sql
-- Author  : Atishay Jain
-- Description :
-- Creates all Dimension Tables required for the Data Warehouse.
-- ==========================================================






- ==========================================================
-- Create  dim_customer Table;
-- ==========================================================




CREATE TABLE dim_customer AS
SELECT
    Customer_ID AS customer_code,
    MAX(Customer_Name) AS Customer_Name,
    MAX(Segment) AS segment
   
FROM raw_orders
GROUP BY Customer_ID; 




 
-- ==========================================================
-- File Name : 04_Create_Dim_Market.sql
-- Description : Create Market Dimension Table
-- ==========================================================

DROP TABLE IF EXISTS dim_market;

CREATE TABLE dim_market AS
SELECT DISTINCT
    CONCAT(market, '|', region, '|', sub_zone) AS geo_key,
    market,
    region,
    sub_zone
FROM helper_clean;




-- ==========================================================
-- File Name : 01_Create_Dim_Date.sql
-- Description : Create Date Dimension Table
-- ==========================================================

-- Create dim_date Table

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
SELECT DISTINCT
    sales_month AS full_date,
    DAY(sales_month) AS day_of_month,
    DAYNAME(sales_month) AS day_name,
    WEEK(sales_month) AS week_of_year,
    MONTH(sales_month) AS month_number,
    MONTHNAME(sales_month) AS month_name,
    QUARTER(sales_month) AS quarter_number,
    CONCAT('Q', QUARTER(sales_month)) AS quarter_name,
    YEAR(sales_month) AS calendar_year,
    YEAR(DATE_ADD(sales_month, INTERVAL 4 MONTH)) AS fiscal_year,
    MONTH(DATE_ADD(sales_month, INTERVAL 4 MONTH)) AS fiscal_month,
    CONCAT('Q', QUARTER(DATE_ADD(sales_month, INTERVAL 4 MONTH))) AS fiscal_quarter,
    CASE
        WHEN DAYOFWEEK(sales_month) IN (1,7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM helper_clean;




- ==========================================================
  Create category table (from dim_product)


-- ==========================================================




DROP TABLE IF EXISTS category;

CREATE TABLE category AS
SELECT DISTINCT
    category
FROM dim_product
ORDER BY category;







 ==========================================================
 
- Create sub_zone table
-- ==========================================================





-

DROP TABLE IF EXISTS sub_zone;

CREATE TABLE sub_zone AS
SELECT DISTINCT
    sub_zone
FROM dim_market
ORDER BY sub_zone;