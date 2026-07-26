-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Views.sql
-- Description  : Creates all Business Views
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- VIEW 1 : gross_sales
-- ==========================================================

DROP VIEW IF EXISTS gross_sales;

CREATE OR REPLACE VIEW gross_sales AS

SELECT
    f.sales_month,
    get_fiscal_year(f.sales_month) AS fiscal_year,
    f.customer_code,
    c.customer_name,
    f.product_code,
    p.product_name,
    p.product_category,
    p.product_division,
    f.market,
    f.region,
    f.sub_zone,
    f.sold_quantity,
    g.gross_price,
    ROUND(g.gross_price * f.sold_quantity,2) AS gross_price_total

FROM fact_sales_monthly f

JOIN dim_customer c
ON f.customer_code = c.customer_code

JOIN dim_product p
ON f.product_code = p.product_code

JOIN gross_price g
ON f.product_code = g.product_code
AND f.customer_code = g.customer_code
AND f.market = g.market
AND f.region = g.region
AND f.sub_zone = g.sub_zone
AND f.sales_month = g.sales_month;



-- ==========================================================
-- VIEW 2 : sales_pre_invoice_deduction
-- ==========================================================

DROP VIEW IF EXISTS sales_pre_invoice_deduction;

CREATE OR REPLACE VIEW sales_pre_invoice_deduction AS

SELECT
    gs.*,
    pre.discount_pct,

    ROUND(
        gs.gross_price_total -
        (gs.gross_price_total * pre.discount_pct),
        2
    ) AS net_invoice_sales

FROM gross_sales gs

JOIN pre_invoice_deduction pre

ON gs.product_code = pre.product_code
AND gs.customer_code = pre.customer_code
AND gs.market = pre.market
AND gs.region = pre.region
AND gs.sub_zone = pre.sub_zone
AND gs.sales_month = pre.sales_month;



-- ==========================================================
-- VIEW 3 : sales_post_invoice_deduction
-- ==========================================================

DROP VIEW IF EXISTS sales_post_invoice_deduction;

CREATE OR REPLACE VIEW sales_post_invoice_deduction AS

SELECT
    sp.*,
    pi.post_discount_pct,
    pi.other_discount_pct,

    ROUND(
        pi.post_discount_pct +
        pi.other_discount_pct,
        4
    ) AS post_invoice_discount_pct

FROM sales_pre_invoice_deduction sp

JOIN post_invoice_deductions pi

ON sp.product_code = pi.product_code
AND sp.customer_code = pi.customer_code
AND sp.market = pi.market
AND sp.region = pi.region
AND sp.sub_zone = pi.sub_zone
AND sp.sales_month = pi.sales_month;



-- ==========================================================
-- VIEW 4 : net_sales
-- ==========================================================

DROP VIEW IF EXISTS net_sales;

CREATE OR REPLACE VIEW net_sales AS

SELECT
    sales_month,
    fiscal_year,
    customer_code,
    customer_name,
    product_code,
    product_name,
    product_category,
    product_division,
    market,
    region,
    sub_zone,
    sold_quantity,
    gross_price,
    gross_price_total,
    discount_pct,
    net_invoice_sales,
    post_discount_pct,
    other_discount_pct,
    post_invoice_discount_pct,

    ROUND(
        net_invoice_sales *
        (1 - post_invoice_discount_pct),
        2
    ) AS net_sales

FROM sales_post_invoice_deduction;



-- ==========================================================
-- VIEW 5 : market_sales
-- ==========================================================

DROP VIEW IF EXISTS market_sales;

CREATE OR REPLACE VIEW market_sales AS

SELECT
    n.sub_zone,
    p.product_category AS category,
    n.fiscal_year AS fy,
    c.segment,

    ROUND(n.net_sales,2) AS sales_$,

    ROUND(
        SUM(n.net_sales) OVER (
            PARTITION BY
                n.sub_zone,
                p.product_category,
                n.fiscal_year
        ),
        2
    ) AS total_market_sales_$

FROM net_sales n

JOIN dim_product p
ON n.product_code = p.product_code

JOIN dim_customer c
ON n.customer_code = c.customer_code;