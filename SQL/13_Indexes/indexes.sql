-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Indexes.sql
-- Description  : Performance Optimization Using Indexes
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- INDEX 1 : fact_sales_monthly
-- ==========================================================

CREATE INDEX idx_sales_customer
ON fact_sales_monthly(customer_code);

CREATE INDEX idx_sales_product
ON fact_sales_monthly(product_code);

CREATE INDEX idx_sales_month
ON fact_sales_monthly(sales_month);

CREATE INDEX idx_sales_market
ON fact_sales_monthly(market, region, sub_zone);

CREATE INDEX idx_sales_fiscal_year
ON fact_sales_monthly(fiscal_year);

CREATE INDEX idx_sales_customer_fy
ON fact_sales_monthly(customer_code, fiscal_year);

CREATE INDEX idx_fact_customer_fy_market
ON fact_sales_monthly(customer_code, fiscal_year, market);



-- ==========================================================
-- INDEX 2 : dim_market
-- ==========================================================

CREATE INDEX idx_market
ON dim_market(market, region, sub_zone);



-- ==========================================================
-- INDEX 3 : gross_price
-- ==========================================================

CREATE INDEX idx_gross_lookup
ON gross_price
(
    customer_code,
    product_code,
    sales_month,
    market,
    region,
    sub_zone
);



-- ==========================================================
-- INDEX 4 : pre_invoice_deduction
-- ==========================================================

CREATE INDEX idx_pre_lookup
ON pre_invoice_deduction
(
    customer_code,
    product_code,
    sales_month,
    market,
    region,
    sub_zone
);



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