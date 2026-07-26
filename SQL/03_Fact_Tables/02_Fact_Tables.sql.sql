-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Fact_Tables.sql
-- Description  : Creates all Fact Tables for the Data Warehouse
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- FACT TABLE 1 : fact_sales_monthly
-- ==========================================================

CREATE TABLE fact_sales_monthly AS
SELECT
DATE_FORMAT(Order_Date,'%Y-%m-01') AS sales_month,
Product_ID AS product_code,
Customer_ID AS customer_code,
 CONCAT(Market,'|',Region,'|',Country) AS geo_key,
Country AS sub_zone,
Region AS region,
Market AS market,
SUM(Quantity) AS sold_quantity
FROM raw_orders
GROUP BY
DATE_FORMAT(Order_Date,'%Y-%m-01'),
product_code,
 geo_key,
customer_code,
sub_zone,
region,
Market;





-- ==========================================================
-- FACT TABLE 2 : fact_forecast_monthly
-- ==========================================================


CREATE TABLE fact_forecast_monthly AS 

WITH base AS (

    SELECT
        sales_month,
        product_code,
        customer_code,
         geo_key,

        market,
        region,
        sub_zone,
        sold_quantity,

        -- same month last year
        LAG(sold_quantity, 12) OVER (
            PARTITION BY
                product_code,
                customer_code,
                market,
                region,
                sub_zone
            ORDER BY sales_month
        ) AS last_year_qty,

        -- previous 3 months avg
        AVG(sold_quantity) OVER (
            PARTITION BY
                product_code,
                customer_code,
                market,
                region,
                sub_zone
            ORDER BY sales_month
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ) AS prev_avg

    FROM fact_sales_monthly
),

calc AS (

    SELECT
        *,

        -- trend type
        CASE

            WHEN sold_quantity > COALESCE(prev_avg, sold_quantity)
            AND sold_quantity > COALESCE(last_year_qty, sold_quantity)
            THEN 'Increasing'

            WHEN sold_quantity < COALESCE(prev_avg, sold_quantity)
            AND sold_quantity < COALESCE(last_year_qty, sold_quantity)
            THEN 'Decreasing'

            ELSE 'Stable'

        END AS trend_type,

        -- growth rate
        CASE

            WHEN last_year_qty IS NULL
            OR last_year_qty = 0
            THEN 0.08

            WHEN sold_quantity > last_year_qty
            THEN LEAST(
                    (sold_quantity - last_year_qty)
                    / last_year_qty,
                    0.25
                 )

            ELSE GREATEST(
                    (sold_quantity - last_year_qty)
                    / last_year_qty,
                    -0.15
                 )

        END AS growth_rate

    FROM base
)

-- ================= SAME YEAR =================
SELECT

    sales_month,
    product_code,
    customer_code,
    market,
    region,
    sub_zone,

    ROUND(

        (
            sold_quantity * 0.60
            + COALESCE(prev_avg, sold_quantity) * 0.40
        )

        *

        CASE

            WHEN trend_type='Increasing'
            THEN (1 + growth_rate + 0.03)

            WHEN trend_type='Decreasing'
            THEN (1 + growth_rate - 0.08)

            ELSE (1 + growth_rate - 0.03)

        END

    ,0) AS forecast_quantity,

    'Forecast' AS data_type

FROM calc

WHERE YEAR(sales_month) BETWEEN 2011 AND 2014

UNION ALL

-- ================= 2015 FORECAST =================
SELECT

    DATE_ADD(sales_month, INTERVAL 1 YEAR) AS sales_month,

    product_code,
    customer_code,
    market,
    region,
    
    sub_zone,

    ROUND(

        (
            sold_quantity * 0.60
            + COALESCE(prev_avg, sold_quantity) * 0.40
        )

        *

        CASE

            WHEN trend_type='Increasing'
            THEN (1 + growth_rate + 0.05)

            WHEN trend_type='Decreasing'
            THEN (1 + growth_rate - 0.12)

            ELSE (1 + growth_rate - 0.02)

        END

    ,0) AS forecast_quantity,

    'Forecast' AS data_type

FROM calc

WHERE YEAR(sales_month)=2014;





-- ================= Create supporting tables =================-- 





-- ==========================================================
-- FACT TABLE 3 : gross_price
-- ==========================================================




CREATE TABLE gross_price AS

WITH base AS (

    SELECT
        DATE_FORMAT(Order_Date,'%Y-%m-01') AS sales_month,

        Product_ID AS product_code,

        Customer_ID AS customer_code,

        Market AS market,

        Region AS region,

        Country AS sub_zone,

        SUM(Quantity) AS total_qty,

        SUM(
            CAST(Sales AS DECIMAL(18,6)) /
            NULLIF((1 - (Discount/100)),0)
        ) AS gross_sales

    FROM raw_orders

    GROUP BY
        DATE_FORMAT(Order_Date,'%Y-%m-01'),
        product_code,
        customer_code,
        market,
        region,
        sub_zone
),

actual_price AS (

    SELECT
        sales_month,
        product_code,
        customer_code,
        market,
        region,
        sub_zone,

        ROUND(
            gross_sales / NULLIF(total_qty,0),
            4
        ) AS gross_price

    FROM base
),

base_2014 AS (

    SELECT
        product_code,
        customer_code,
        market,
        region,
        sub_zone,

        SUM(gross_price) AS total_2014_price

    FROM actual_price

    WHERE YEAR(sales_month)=2014

    GROUP BY
        product_code,
        customer_code,
        market,
        region,
        sub_zone
)

-- ================= ACTUAL =================
SELECT

    sales_month,

    product_code,

    customer_code,

    market,

    region,

    sub_zone,

    gross_price,

    'Actual' AS data_type

FROM actual_price

WHERE YEAR(sales_month) <= 2014


UNION ALL


-- ================= FORECAST =================
SELECT

    DATE_ADD(a.sales_month, INTERVAL 1 YEAR),

    a.product_code,

    a.customer_code,

    a.market,

    a.region,

    a.sub_zone,

    ROUND(
        b.total_2014_price * 1.05 / 12,
        4
    ),

    'Forecast'

FROM actual_price a

JOIN base_2014 b

ON a.product_code = b.product_code
AND a.customer_code = b.customer_code
AND a.market = b.market
AND a.region = b.region
AND a.sub_zone = b.sub_zone

WHERE YEAR(a.sales_month)=2014;







 -- ==========================================================
-- FACT TABLE 4 :  pre_invoice_deduction Table;
-- ==========================================================



CREATE TABLE pre_invoice_deduction AS

-- ================= BASE SALES =================

WITH base AS (
    SELECT
        DATE_FORMAT(Order_Date,'%Y-%m-01') AS sales_month,
        Customer_ID AS customer_code,
        Product_ID AS product_code,
        Market AS market,
        Region AS region,
        Country AS sub_zone,

        SUM(
            Sales /
            NULLIF(1 - (Discount/100.0),0)
        ) AS gross_sales

    FROM raw_orders

    GROUP BY
        DATE_FORMAT(Order_Date,'%Y-%m-01'),
        customer_code,
        product_code,
        market,
        region,
        sub_zone
),

yearly_perf AS (
    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,

        YEAR(sales_month) AS yr,

        SUM(gross_sales) AS total_year_sales

    FROM base

    WHERE YEAR(sales_month) BETWEEN 2011 AND 2014

    GROUP BY
        customer_code,
        product_code,
        market,
        region,
        sub_zone,
        YEAR(sales_month)
),

ranked AS (
    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,
        yr,

        NTILE(3) OVER (
            PARTITION BY yr
            ORDER BY total_year_sales DESC
        ) AS grp

    FROM yearly_perf
),

rank_2014 AS (
    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,

        NTILE(3) OVER (
            ORDER BY SUM(gross_sales) DESC
        ) AS grp

    FROM base

    WHERE YEAR(sales_month)=2014

    GROUP BY
        customer_code,
        product_code,
        market,
        region,
        sub_zone
)

SELECT
    b.sales_month,
    b.customer_code,
    b.product_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r.grp=1 THEN 0.05
        WHEN r.grp=2 THEN 0.065
        ELSE 0.08
    END AS discount_pct

FROM base b

LEFT JOIN ranked r
ON b.customer_code = r.customer_code
AND b.product_code = r.product_code
AND b.market = r.market
AND b.region = r.region
AND b.sub_zone = r.sub_zone
AND YEAR(b.sales_month) = r.yr

WHERE YEAR(b.sales_month) BETWEEN 2011 AND 2014


UNION ALL


SELECT
    DATE_ADD(b.sales_month,INTERVAL 1 YEAR),
    b.customer_code,
    b.product_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r14.grp=1 THEN 0.06
        WHEN r14.grp=2 THEN 0.075
        ELSE 0.09
    END

FROM base b

LEFT JOIN rank_2014 r14
ON b.customer_code = r14.customer_code
AND b.product_code = r14.product_code
AND b.market = r14.market
AND b.region = r14.region
AND b.sub_zone = r14.sub_zone

WHERE YEAR(b.sales_month)=2014;







-- ==========================================================
-- FACT TABLE 5 :  post_invoice_deduction Table;
-- ==========================================================--


CREATE TABLE post_invoice_deductions AS

WITH base AS (

    SELECT
        DATE_FORMAT(Order_Date,'%Y-%m-01') AS sales_month,
        Product_ID AS product_code,
        Customer_ID AS customer_code,
        Market AS market,
        Region AS region,
        Country AS sub_zone,

        SUM(
            Sales /
            NULLIF(1 - (Discount/100.0),0)
        ) AS gross_sales

    FROM raw_orders

    GROUP BY
        DATE_FORMAT(Order_Date,'%Y-%m-01'),
        product_code,
        customer_code,
      
        market,
        region,
         sub_zone
),

yearly_perf AS (

    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,

        YEAR(sales_month) AS yr,

        SUM(gross_sales) AS total_year_sales

    FROM base

    WHERE YEAR(sales_month) BETWEEN 2011 AND 2014

    GROUP BY
        customer_code,
        product_code,
        market,
        region,
        sub_zone,
        YEAR(sales_month)
),

ranked AS (

    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,
        yr,

        NTILE(3) OVER (
            PARTITION BY yr
            ORDER BY total_year_sales DESC
        ) AS grp

    FROM yearly_perf
),

rank_2014 AS (

    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,

        NTILE(3) OVER (
            ORDER BY SUM(gross_sales) DESC
        ) AS grp

    FROM base

    WHERE YEAR(sales_month)=2014

    GROUP BY
        customer_code,
        product_code,
        market,
        region,
        sub_zone
)

SELECT
    b.sales_month,
    b.product_code,
    b.customer_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r.grp=1 THEN 0.03
        WHEN r.grp=2 THEN 0.04
        ELSE 0.05
    END AS post_discount_pct,

    CASE
        WHEN r.grp=1 THEN 0.015
        WHEN r.grp=2 THEN 0.02
        ELSE 0.025
    END AS other_discount_pct

FROM base b

LEFT JOIN ranked r
ON b.customer_code = r.customer_code
AND b.product_code = r.product_code
AND b.market = r.market
AND b.region = r.region
AND b.sub_zone = r.sub_zone
AND YEAR(b.sales_month) = r.yr

WHERE YEAR(b.sales_month) BETWEEN 2011 AND 2014


UNION ALL


SELECT
    DATE_ADD(b.sales_month,INTERVAL 1 YEAR),
    b.product_code,
    b.customer_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r14.grp=1 THEN 0.035
        WHEN r14.grp=2 THEN 0.045
        ELSE 0.055
    END,

    CASE
        WHEN r14.grp=1 THEN 0.02
        WHEN r14.grp=2 THEN 0.025
        ELSE 0.03
    END

FROM base b

LEFT JOIN rank_2014 r14
ON b.customer_code = r14.customer_code
AND b.product_code = r14.product_code
AND b.market = r14.market
AND b.region = r14.region
AND b.sub_zone = r14.sub_zone

WHERE YEAR(b.sales_month)=2014

AND DATE_ADD(b.sales_month,INTERVAL 1 YEAR) <= '2015-03-01';








-- ==========================================================
-- FACT TABLE 6 :   manufacturing_cost Table
-- ==========================================================-- 

DROP TABLE IF EXISTS manufacturing_cost;
CREATE TABLE manufacturing_cost AS

WITH base AS (

    SELECT
        DATE_FORMAT(Order_Date,'%Y-%m-01') AS sales_month,
        Product_ID AS product_code,
        Customer_ID AS customer_code,
        Market AS market,
        Region AS region,
        Country AS sub_zone,

        SUM(
            Sales /
            NULLIF(1 - (Discount/100.0),0)
        ) AS gross_sales

    FROM raw_orders

    GROUP BY
        DATE_FORMAT(Order_Date,'%Y-%m-01'),
        product_code,
        customer_code,
        market,
        region,
        sub_zone
),

yearly_perf AS (

    SELECT
        product_code,
        customer_code,
        market,
        region,
        sub_zone,

        YEAR(sales_month) AS yr,

        SUM(gross_sales) AS total_year_sales

    FROM base

    WHERE YEAR(sales_month) BETWEEN 2011 AND 2014

    GROUP BY
        product_code,
        customer_code,
        market,
        region,
        sub_zone,
        YEAR(sales_month)
),

ranked AS (

    SELECT
        product_code,
        customer_code,
        market,
        region,
        sub_zone,
        yr,

        NTILE(3) OVER (
            PARTITION BY yr
            ORDER BY total_year_sales DESC
        ) AS grp

    FROM yearly_perf
),

rank_2014 AS (

    SELECT
        product_code,
        customer_code,
        market,
        region,
        sub_zone,

        NTILE(3) OVER (
            ORDER BY SUM(gross_sales) DESC
        ) AS grp

    FROM base

    WHERE YEAR(sales_month)=2014

    GROUP BY
        product_code,
        customer_code,
        market,
        region,
        sub_zone
)

SELECT
    b.sales_month,
    b.product_code,
    b.customer_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r.grp=1 THEN 0.62
        WHEN r.grp=2 THEN 0.66
        ELSE 0.70
    END AS manufacturing_pct

FROM base b

LEFT JOIN ranked r
ON b.product_code = r.product_code
AND b.customer_code = r.customer_code
AND b.market = r.market
AND b.region = r.region
AND b.sub_zone = r.sub_zone
AND YEAR(b.sales_month) = r.yr

WHERE YEAR(b.sales_month) BETWEEN 2011 AND 2014


UNION ALL


SELECT
    DATE_ADD(b.sales_month,INTERVAL 1 YEAR),
    b.product_code,
    b.customer_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r14.grp=1 THEN 0.64
        WHEN r14.grp=2 THEN 0.68
        ELSE 0.72
    END

FROM base b

LEFT JOIN rank_2014 r14
ON b.product_code = r14.product_code
AND b.customer_code = r14.customer_code
AND b.market = r14.market
AND b.region = r14.region
AND b.sub_zone = r14.sub_zone

WHERE YEAR(b.sales_month)=2014
AND DATE_ADD(b.sales_month,INTERVAL 1 YEAR) <= '2015-03-01';





;


-- ==========================================================
-- FACT TABLE 7: -- freight_cost Table;
-- ==========================================================-- 



CREATE TABLE freight_cost AS

WITH base AS (

    SELECT
        DATE_FORMAT(Order_Date,'%Y-%m-01') AS sales_month,
        Product_ID AS product_code,
        Customer_ID AS customer_code,
        Market AS market,
        Region AS region,
        Country AS sub_zone,

        SUM(
            Sales /
            NULLIF(1 - (Discount/100.0),0)
        ) AS gross_sales

    FROM raw_orders

    GROUP BY
        DATE_FORMAT(Order_Date,'%Y-%m-01'),
        product_code,
        customer_code,
        market,
        region,
        sub_zone
),

yearly_perf AS (

    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,

        YEAR(sales_month) AS yr,

        SUM(gross_sales) AS total_year_sales

    FROM base

    WHERE YEAR(sales_month) BETWEEN 2011 AND 2014

    GROUP BY
        customer_code,
        product_code,
        market,
        region,
        sub_zone,
        YEAR(sales_month)
),

ranked AS (

    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,
        yr,

        NTILE(3) OVER (
            PARTITION BY yr
            ORDER BY total_year_sales DESC
        ) AS grp

    FROM yearly_perf
),

rank_2014 AS (

    SELECT
        customer_code,
        product_code,
        market,
        region,
        sub_zone,

        NTILE(3) OVER (
            ORDER BY SUM(gross_sales) DESC
        ) AS grp

    FROM base

    WHERE YEAR(sales_month)=2014

    GROUP BY
        customer_code,
        product_code,
        market,
        region,
        sub_zone
)

SELECT
    b.sales_month,
    b.product_code,
    b.customer_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r.grp=1 THEN 0.04
        WHEN r.grp=2 THEN 0.05
        ELSE 0.07
    END AS freight_pct,

    CASE
        WHEN r.grp=1 THEN 0.02
        WHEN r.grp=2 THEN 0.03
        ELSE 0.05
    END AS other_pct

FROM base b

LEFT JOIN ranked r
ON b.customer_code = r.customer_code
AND b.product_code = r.product_code
AND b.market = r.market
AND b.region = r.region
AND b.sub_zone = r.sub_zone
AND YEAR(b.sales_month) = r.yr

WHERE YEAR(b.sales_month) BETWEEN 2011 AND 2014


UNION ALL


SELECT
    DATE_ADD(b.sales_month,INTERVAL 1 YEAR),
    b.product_code,
    b.customer_code,
    b.market,
    b.region,
    b.sub_zone,

    CASE
        WHEN r14.grp=1 THEN 0.045
        WHEN r14.grp=2 THEN 0.055
        ELSE 0.075
    END,

    CASE
        WHEN r14.grp=1 THEN 0.025
        WHEN r14.grp=2 THEN 0.035
        ELSE 0.055
    END

FROM base b

LEFT JOIN rank_2014 r14
ON b.customer_code = r14.customer_code
AND b.product_code = r14.product_code
AND b.market = r14.market
AND b.region = r14.region
AND b.sub_zone = r14.sub_zone

WHERE YEAR(b.sales_month)=2014;






-- ==========================================================
-- FACT TABLE 8 : helper_clean
-- ==========================================================


CREATE TABLE helper AS

SELECT

    f.sales_month,

    f.customer_code,

    f.market,

    f.region,

    f.sub_zone,
geo_key,

    f.product_code,

    f.sold_quantity,

    COALESCE(ff.forecast_quantity,0) AS forecast_quantity

FROM fact_sales_monthly f

LEFT JOIN fact_forecast_monthly ff

ON f.sales_month = ff.sales_month
AND f.product_code = ff.product_code
AND f.customer_code = ff.customer_code
AND f.market = ff.market
AND f.region = ff.region
AND f.sub_zone = ff.sub_zone;







-- ==========================================================
-- FACT TABLE 9 : Aggregate helper_clean
-- ==========================================================


CREATE TABLE helper_clean AS

SELECT

    sales_month,

    customer_code,

    market,
     geo_key,

    region,

    sub_zone,

    product_code,

    SUM(sold_quantity) AS sold_quantity,

    SUM(forecast_quantity) AS forecast_quantity

FROM helper

GROUP BY

sales_month,
customer_code,
geo_key,
market,
region,
sub_zone,
product_code;




--

-- ==========================================================
-- FACT TABLE 10 : market_sales
-- ==========================================================


CREATE Table  market_sales AS

SELECT

    n.sub_zone,

    p.product_category AS category,

    n.fiscal_year AS fy,

    c.segment,

    ROUND(n.net_sales,2) AS sales_$,

    ROUND(

        SUM(n.net_sales) OVER(

            PARTITION BY
                n.sub_zone,
                p.product_category,
                n.fiscal_year

        ),

    2) AS total_market_sales_$

FROM net_sales n

JOIN dim_product p
ON n.product_code = p.product_code

JOIN dim_customer c
ON n.customer_code = c.customer_code;








-- ==========================================================
-- FACT TABLE 10 : operational_expense TABLE 
-- ==========================================================

CREATE TABLE operational_expense AS
SELECT
    market,
    region,
    sub_zone,
    geo_key
    fiscal_year,
    SUM(net_sales) AS total_net_sales,

    CASE
        WHEN SUM(net_sales) >= 200000 THEN 0.060
        WHEN SUM(net_sales) >= 100000 THEN 0.055
        WHEN SUM(net_sales) >= 50000 THEN 0.050
        WHEN SUM(net_sales) >= 20000 THEN 0.045
        WHEN SUM(net_sales) >= 10000 THEN 0.040
        ELSE 0.035
    END AS ads_promotions_pct,

    CASE
        WHEN SUM(net_sales) >= 200000 THEN 0.075
        WHEN SUM(net_sales) >= 100000 THEN 0.070
        WHEN SUM(net_sales) >= 50000 THEN 0.065
        WHEN SUM(net_sales) >= 20000 THEN 0.060
        WHEN SUM(net_sales) >= 10000 THEN 0.055
        ELSE 0.050
    END AS other_operational_expense_pct

FROM net_sales
GROUP BY
    market,
    region,
    geo_key
    sub_zone,
    fiscal_year;





