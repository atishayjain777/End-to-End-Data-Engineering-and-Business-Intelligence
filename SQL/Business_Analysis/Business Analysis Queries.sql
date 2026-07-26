-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 09_Business_Analysis.sql
-- Description  : Business Analysis Queries
-- Database     : global_estore
-- ==========================================================



 -- ==========================================================
-- CUSTOMER ANALYSIS
-- ==========================================================

-- ========================================================

-- QUERY ...

-
-- ==========================================================
-- QUERY 1 : Total Sold Quantity for Customer Jane Waco (FY 2014)
-- ==========================================================



SELECT
    f.market,
    SUM(f.sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly f
WHERE get_fiscal_year(f.sales_month) = 2014
  AND f.customer_code = 'JW-15220'
  AND f.market = 'US'
GROUP BY f.market;




-- ==========================================================
-- QUERY 2 : Monthly Sales Transactions (FY 2013)
-- ==========================================================


SELECT
    f.sales_month,
    p.product_code,
    c.customer_code,
    m.market
FROM fact_sales_monthly f
JOIN dim_customer c
    ON f.customer_code = c.customer_code
JOIN dim_market m
    ON f.market = m.market
   AND f.region = m.region
   AND f.sub_zone = m.sub_zone
JOIN dim_product p
    ON f.product_code = p.product_code
WHERE f.customer_code = 'JW-15220'
  AND get_fiscal_year(f.sales_month) = 2013
  AND f.market = 'US'
ORDER BY f.sales_month;









-- ==========================================================
-- QUERY 3 : -- Sales Transactions of Customer Jane Waco (FY 2013 - Quarter 4)

-- ==========================================================


SELECT
    f.sales_month,
    f.product_code,
    p.product_name,
    p.product_category,
    f.sold_quantity,
    g.gross_price,
    (g.gross_price * f.sold_quantity) AS gross_price_total

FROM fact_sales_monthly f

JOIN dim_product p
    ON f.product_code = p.product_code

JOIN gross_price g
    ON f.product_code = g.product_code
   AND f.customer_code = g.customer_code
   AND f.sales_month = g.sales_month
   AND f.market = g.market
   AND f.region = g.region
   AND f.sub_zone = g.sub_zone

WHERE f.customer_code = 'JW-15220'
  AND get_fiscal_year(f.sales_month) = 2013
  AND get_fiscal_year_quarter(f.sales_month) = 'Q4'

ORDER BY f.sales_month;





-- ==========================================================
-- QUERY 4 :  Monthly Sales of Customer Jane Waco in us market
-- ==========================================================


SELECT
    f.sales_month,
    ROUND(SUM(g.gross_price * f.sold_quantity),2) AS monthly_sales

FROM fact_sales_monthly f

JOIN gross_price g
    ON f.product_code = g.product_code
   AND f.customer_code = g.customer_code
   AND f.sales_month = g.sales_month
   AND f.market = g.market
   AND f.region = g.region
   AND f.sub_zone = g.sub_zone

WHERE f.customer_code = 'JW-15220'

GROUP BY f.sales_month

ORDER BY f.sales_month;




-- ==========================================================
-- QUERY 5 :  Yearly Sales of Jane Waco in US Market
-- ==========================================================


SELECT

    get_fiscal_year(f.sales_month) AS fiscal_year,

    ROUND(
        SUM(g.gross_price * f.sold_quantity),2
    ) AS yearly_sales

FROM fact_sales_monthly f

JOIN gross_price g
    ON f.product_code = g.product_code
   AND f.customer_code = g.customer_code
   AND f.sales_month = g.sales_month
   AND f.market = g.market
   AND f.region = g.region
   AND f.sub_zone = g.sub_zone

WHERE f.customer_code = 'JW-15220'
  AND f.market = 'US'

GROUP BY fiscal_year

ORDER BY fiscal_year;




-- ==========================================================
-- QUERY 6 : Top 10 Customers by Net Sales
-- ==========================================================
# 

SELECT

    c.customer_name,

    ROUND(
        SUM(n.net_sales),
        2
    ) AS total_net_sales

FROM net_sales n

JOIN dim_customer c
ON n.customer_code = c.customer_code

GROUP BY c.customer_name

ORDER BY total_net_sales DESC

LIMIT 10;



-- ==========================================================
-- QUERY 7 : Top 10 Customers by Gross Sales

-- ==========================================================
# 

SELECT
    c.customer_name,
    ROUND(SUM(g.gross_price*f.sold_quantity),2) AS gross_sales
FROM fact_sales_monthly f
JOIN dim_customer c ON f.customer_code=c.customer_code
JOIN gross_price g
ON f.product_code=g.product_code
AND f.customer_code=g.customer_code
AND f.sales_month=g.sales_month
AND f.market=g.market
AND f.region=g.region
AND f.sub_zone=g.sub_zone
GROUP BY c.customer_name
ORDER BY gross_sales DESC
LIMIT 10;





-- ==========================================================
-- QUERY 8 : Customer Purchase Frequency
-- ==========================================================



SELECT
customer_code,
COUNT(DISTINCT sales_month) AS active_months
FROM fact_sales_monthly
GROUP BY customer_code
ORDER BY active_months DESC;





-- ==========================================================
-- QUERY 9 : Average Monthly Purchase per Customer
-- ==========================================================


SELECT
customer_code,
ROUND(AVG(sold_quantity),2) AS avg_monthly_qty
FROM fact_sales_monthly
GROUP BY customer_code;










-- ==========================================================
-- QUERY 10: -- RFM Analysis of Customers
-- ==========================================================


SELECT

customer_code,

MAX(sales_month),

COUNT(*) frequency,

SUM(net_sales) monetary

FROM net_sales

GROUP BY customer_code;



-- ==========================================================
-- QUERY 11 : -- Top Customers by Transactions
-- ==========================================================



SELECT
customer_code,
COUNT(*) AS total_transactions
FROM fact_sales_monthly
GROUP BY customer_code
ORDER BY total_transactions DESC
LIMIT 10;










-- ==========================================================
-- MARKET ANALYSIS
-- ==========================================================

-- QUERY ...



-- ==========================================================
-- MARKET ANALYSIS
-- ==========================================================


-- Sales Distribution by Market


SELECT
market,
COUNT(*) AS transactions
FROM helper_clean
GROUP BY market
ORDER BY transactions DESC;




-- ==========================================================
-- -- Top Markets by Net Sales (FY 2011)
-- ==========================================================


SELECT

    market,

    ROUND(
        SUM(net_sales)/1000000,
        2
    ) AS net_sales_mln

FROM net_sales

WHERE fiscal_year = 2011

GROUP BY market

ORDER BY net_sales_mln DESC;







-- ==========================================================
-- -- Market Wise Customer Contribution by net_sales_mln
-- ==========================================================


WITH customer_market_sales AS (

SELECT

    c.customer_name,

    n.market,

    ROUND(
        SUM(n.net_sales)/1000000,
        2
    ) AS net_sales_mln

FROM net_sales n

JOIN dim_customer c

ON n.customer_code=c.customer_code

WHERE n.fiscal_year=2011

GROUP BY

c.customer_name,

n.market

)

SELECT

*,

ROUND(

(net_sales_mln*100)

/SUM(net_sales_mln)
OVER(PARTITION BY market)

,2) AS contribution_pct

FROM customer_market_sales

ORDER BY

market,

contribution_pct DESC;









-- ==========================================================
--   -- Average Net Sales by Market
-- ==========================================================

SELECT
market,
ROUND(AVG(net_sales),2) AS avg_sales
FROM net_sales
GROUP BY market;




-- ==========================================================
-- - _Product_Analysis.sql
-- ==========================================================

-- QUERY ...

- ==========================================================
-- Top Products by Transactions
-- ==========================================================-- 

SELECT
product_code,
COUNT(*) AS total_transactions
FROM fact_sales_monthly
GROUP BY product_code
ORDER BY total_transactions DESC
LIMIT 10;





- ==========================================================
-- Lowest Selling Products
-- ==========================================================# 

SELECT
product_name,
SUM(net_sales) total_sales
FROM net_sales
GROUP BY product_name
ORDER BY total_sales
LIMIT 10;







-- ==========================================================
-- - Product Wise Sold Quantity (FY 2011)
-- ==========================================================
-

SELECT

    p.product_name,

    p.product_division,

    SUM(f.sold_quantity) AS total_quantity

FROM fact_sales_monthly f

JOIN dim_product p
ON f.product_code = p.product_code

WHERE get_fiscal_year(f.sales_month) = 2011

GROUP BY

p.product_name,
p.product_division

ORDER BY total_quantity DESC;




-- ==========================================================
---- Product Contribution %
-- ==========================================================


SELECT
product_name,
ROUND(
SUM(net_sales)*100/
(SUM(SUM(net_sales)) OVER()),
2
) contribution_pct
FROM net_sales
GROUP BY product_name
ORDER BY contribution_pct DESC;




-- ==========================================================
-- Product Performance by Market
-- ==========================================================


SELECT

    f.market,

    p.product_name,

    SUM(f.sold_quantity) AS total_quantity,

    ROUND(
        SUM(g.gross_price*f.sold_quantity),
        2
    ) AS gross_sales

FROM fact_sales_monthly f

JOIN dim_product p
ON f.product_code=p.product_code

JOIN gross_price g
ON f.product_code=g.product_code
AND f.customer_code=g.customer_code
AND f.sales_month=g.sales_month
AND f.market=g.market
AND f.region=g.region
AND f.sub_zone=g.sub_zone

GROUP BY

f.market,
p.product_name

ORDER BY gross_sales DESC;




- ==========================================================
-- Product Category Sales
-- ==========================================================-- 

SELECT

    p.product_category,

    SUM(f.sold_quantity) AS total_quantity,

    ROUND(
        SUM(g.gross_price*f.sold_quantity),
        2
    ) AS gross_sales

FROM fact_sales_monthly f

JOIN dim_product p
ON f.product_code=p.product_code

JOIN gross_price g
ON f.product_code=g.product_code
AND f.customer_code=g.customer_code
AND f.sales_month=g.sales_month
AND f.market=g.market
AND f.region=g.region
AND f.sub_zone=g.sub_zone

GROUP BY p.product_category

ORDER BY gross_sales DESC;










-- ==========================================================
-- Sales_Analysis.sql
-- ==========================================================--

-- QUERY ... 


- ==========================================================
--  Gross Sales Summary
-- ==========================================================--
--

SELECT

    f.sales_month,

    f.market,

    ROUND(
        SUM(g.gross_price * f.sold_quantity),
        2
    ) AS gross_sales

FROM fact_sales_monthly f

JOIN gross_price g
ON f.product_code = g.product_code
AND f.customer_code = g.customer_code
AND f.sales_month = g.sales_month
AND f.market = g.market
AND f.region = g.region
AND f.sub_zone = g.sub_zone

GROUP BY
    f.sales_month,
    f.market

ORDER BY
    f.sales_month;







--==========================================================
    Gross Sales by Customer
-- ==========================================================-- 

SELECT

    c.customer_name,

    ROUND(
        SUM(g.gross_price * f.sold_quantity),
        2
    ) AS gross_sales

FROM fact_sales_monthly f

JOIN dim_customer c
ON f.customer_code = c.customer_code

JOIN gross_price g
ON f.product_code = g.product_code
AND f.customer_code = g.customer_code
AND f.sales_month = g.sales_month
AND f.market = g.market
AND f.region = g.region
AND f.sub_zone = g.sub_zone

GROUP BY
    c.customer_name

ORDER BY gross_sales DESC;




- ==========================================================
- Gross Sales by Market
-- ==========================================================-

SELECT

    market,

    ROUND(
        SUM(gross_price_total),
        2
    ) AS gross_sales

FROM sales_pre_invoice_deduction

GROUP BY market

ORDER BY gross_sales DESC;






- ==========================================================
Net Invoice Sales Summary
-- ==========================================================-- 

SELECT

    sales_month,

    market,

    ROUND(
        SUM(net_invoice_sales),
        2
    ) AS total_net_invoice_sales

FROM sales_post_invoice_deduction

GROUP BY
    sales_month,
    market

ORDER BY
    sales_month;






- ==========================================================
 Net Sales by Market
-- ==========================================================--

SELECT

    market,

    ROUND(
        SUM(net_sales),
        2
    ) AS total_net_sales

FROM net_sales

GROUP BY market

ORDER BY total_net_sales DESC;





- ==========================================================
Net Sales by Fiscal Year
-- ==========================================================-- 

SELECT

    fiscal_year,

    ROUND(
        SUM(net_sales),
        2
    ) AS total_net_sales

FROM net_sales

GROUP BY fiscal_year

ORDER BY fiscal_year;






- ==========================================================
Monthly Net Sales Trend
-- ==========================================================-- 

SELECT

    sales_month,

    ROUND(
        SUM(net_sales),
        2
    ) AS monthly_net_sales

FROM net_sales

GROUP BY sales_month

ORDER BY sales_month;


- ==========================================================
Top 10 Products by Net Sales
-- ==========================================================-- 

SELECT

    product_name,

    ROUND(
        SUM(net_sales),
        2
    ) AS total_net_sales

FROM net_sales

GROUP BY product_name

ORDER BY total_net_sales DESC

LIMIT 10;




-- ==========================================================
- Sales by Product Category
-- ==========================================================-

SELECT

    product_category,

    ROUND(
        SUM(net_sales),
        2
    ) AS total_net_sales

FROM net_sales

GROUP BY product_category

ORDER BY total_net_sales DESC;



-- ==========================================================
- Quarterly Sales Trend
-- ==========================================================--- 

SELECT
fiscal_year

SUM(net_sales) total_sales
get_fiscal_year_quarter(sales_month) = 'Q4' AS quarter

FROM net_sales
GROUP BY fiscal_year,quarter;














- ==========================================================
Delete Records Older Than 5 Days
-- ==========================================================-- 

DELETE

FROM random_tables.session_logs

WHERE ts < DATE_SUB(CURDATE(),INTERVAL 5 DAY);



-- CREATE EVENT SCHEDULER
DELIMITER $$

CREATE EVENT e_daily_log_purge

ON SCHEDULE EVERY 1 DAY

DO

BEGIN

DELETE

FROM random_tables.session_logs

WHERE ts < DATE_SUB(CURDATE(),INTERVAL 5 DAY);

END$$

DELIMITER ;











