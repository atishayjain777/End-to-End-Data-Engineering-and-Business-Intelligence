-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Data_Validation.sql
-- Description  : Data Validation & Data Quality Checks
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- QUERY 1 : Duplicate Detection
-- ==========================================================

SELECT

    customer_code,
    product_code,
    sales_month,
    market,
    region,
    sub_zone,

    COUNT(*) AS duplicate_rows

FROM helper_clean

GROUP BY

    customer_code,
    product_code,
    sales_month,
    market,
    region,
    sub_zone

HAVING COUNT(*) > 1;



-- ==========================================================
-- QUERY 2 : NULL Value Check
-- ==========================================================

SELECT

    SUM(customer_code IS NULL) AS customer_null,

    SUM(product_code IS NULL) AS product_null,

    SUM(market IS NULL) AS market_null,

    SUM(region IS NULL) AS region_null,

    SUM(sub_zone IS NULL) AS sub_zone_null,

    SUM(sold_quantity IS NULL) AS sold_qty_null

FROM helper_clean;



-- ==========================================================
-- QUERY 3 : Orphan Records (Foreign Key Validation)
-- ==========================================================

SELECT

    f.customer_code

FROM helper_clean f

LEFT JOIN dim_customer c
ON f.customer_code = c.customer_code

WHERE c.customer_code IS NULL;



-- ==========================================================
-- QUERY 4 : Missing Markets
-- ==========================================================

SELECT

    *

FROM helper_clean f

LEFT JOIN dim_market m

ON f.market = m.market
AND f.region = m.region
AND f.sub_zone = m.sub_zone

WHERE m.market IS NULL;



-- ==========================================================
-- QUERY 5 : Missing Products
-- ==========================================================

SELECT

    f.product_code

FROM helper_clean f

LEFT JOIN dim_product p

ON f.product_code = p.product_code

WHERE p.product_code IS NULL;



-- ==========================================================
-- QUERY 6 : Data Quality Dashboard
-- ==========================================================

SELECT

    COUNT(*) AS total_rows,

    COUNT(DISTINCT customer_code) AS customers,

    COUNT(DISTINCT product_code) AS products,

    COUNT(DISTINCT market) AS markets

FROM helper_clean;



-- ==========================================================
-- QUERY 7 : Referential Integrity Check
-- ==========================================================

SELECT DISTINCT

    customer_code

FROM helper_clean

WHERE customer_code NOT IN (

    SELECT customer_code

    FROM dim_customer

);



-- ==========================================================
-- QUERY 8 : Invalid Gross Price
-- ==========================================================

SELECT *

FROM gross_price

WHERE gross_price <= 0;



-- ==========================================================
-- QUERY 9 : Invalid Manufacturing Cost
-- ==========================================================

SELECT *

FROM manufacturing_cost

WHERE manufacturing_cost < 0;



-- ==========================================================
-- QUERY 10 : Invalid Freight Percentage
-- ==========================================================

SELECT *

FROM freight_cost

WHERE freight_pct < 0;



-- ==========================================================
-- QUERY 11 : Negative Sold Quantity
-- ==========================================================

SELECT *

FROM helper_clean

WHERE sold_quantity < 0;



-- ==========================================================
-- QUERY 12 : Outlier Detection (High Sold Quantity)
-- ==========================================================

SELECT *

FROM helper_clean

WHERE sold_quantity > 100000;