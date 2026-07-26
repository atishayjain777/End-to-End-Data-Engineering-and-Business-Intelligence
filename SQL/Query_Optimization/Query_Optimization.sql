-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Indexes.sql
-- Description  : Query_Optimization
-- Database     : global_estore
-- ===================================================


-- ==========================================================
-- QUERY : Performance Analysis Using EXPLAIN ANALYZE
-- ==========================================================

EXPLAIN ANALYZE

SELECT

    f.sales_month,

    f.product_code,

    p.product_name,

    p.product_segment,

    f.sold_quantity,

    c.customer_code,

    m.market,

    g.gross_price,

    g.gross_price * f.sold_quantity AS gross_price_total,

    pre.discount_pct

FROM fact_sales_monthly f

JOIN dim_product p
    ON f.product_code = p.product_code

JOIN dim_customer c
    ON f.customer_code = c.customer_code

JOIN dim_market m
    ON f.market = m.market
   AND f.region = m.region
   AND f.sub_zone = m.sub_zone

JOIN gross_price g
    ON f.customer_code = g.customer_code
   AND f.product_code = g.product_code
   AND f.sales_month = g.sales_month
   AND f.market = g.market
   AND f.region = g.region
   AND f.sub_zone = g.sub_zone

JOIN pre_invoice_deduction pre
    ON f.customer_code = pre.customer_code
   AND f.product_code = pre.product_code
   AND f.sales_month = pre.sales_month
   AND f.market = pre.market
   AND f.region = pre.region
   AND f.sub_zone = pre.sub_zone

WHERE c.customer_code = 'JW-15220'
  AND f.fiscal_year = 2013
  AND f.market = 'US'

LIMIT 1000;




-- ==========================================================
-- QUERY 2 : Execution Plan Analysis
-- ==========================================================

EXPLAIN ANALYZE

SELECT

    c.customer_name,

    SUM(n.net_sales) AS total_sales

FROM net_sales n

JOIN dim_customer c
ON n.customer_code=c.customer_code

WHERE n.fiscal_year=2013

GROUP BY c.customer_name;




-- ==========================================================
-- QUERY 2 : Optimized JOIN
-- ==========================================================

EXPLAIN ANALYZE

SELECT

    f.sales_month,

    p.product_name,

    c.customer_name,

    f.sold_quantity

FROM fact_sales_monthly f

INNER JOIN dim_product p
ON f.product_code=p.product_code

INNER JOIN dim_customer c
ON f.customer_code=c.customer_code

WHERE f.fiscal_year=2013

LIMIT 500;




-- ==========================================================
-- QUERY 4 : Aggregation Optimization
-- ==========================================================

EXPLAIN ANALYZE

SELECT

    market,

    SUM(sold_quantity) total_quantity

FROM fact_sales_monthly

WHERE fiscal_year=2013

GROUP BY market;




-- ==========================================================
-- QUERY 5 : CTE vs Subquery
-- ==========================================================

WITH customer_sales AS
(
    SELECT

        customer_code,

        SUM(net_sales) total_sales

    FROM net_sales

    GROUP BY customer_code
)

SELECT *

FROM customer_sales

WHERE total_sales>1000000;




-- ==========================================================
-- QUERY 6 : Verify Index Usage
-- ==========================================================

EXPLAIN ANALYZE

SELECT *

FROM fact_sales_monthly

WHERE

customer_code='JW-15220'

AND fiscal_year=2013;



