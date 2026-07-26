
-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Window_Functions.sql
-- Description  : Window Function Analysis Queries
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- QUERY 1 : Running Total
-- ==========================================================

SELECT

    sales_month,

    SUM(net_sales) AS total_sales,

    SUM(SUM(net_sales))
    OVER (
        ORDER BY sales_month
    ) AS running_sales

FROM net_sales

GROUP BY sales_month;



-- ==========================================================
-- QUERY 2 : Moving Average
-- ==========================================================

SELECT

    sales_month,

    SUM(net_sales) AS sales,

    AVG(SUM(net_sales))
    OVER (
        ORDER BY sales_month
        ROWS BETWEEN 2 PRECEDING
        AND CURRENT ROW
    ) AS moving_avg

FROM net_sales

GROUP BY sales_month;



-- ==========================================================
-- QUERY 3 : Year-over-Year Growth
-- ==========================================================

WITH yearly_sales AS
(
    SELECT

        fiscal_year,

        SUM(net_sales) AS sales

    FROM net_sales

    GROUP BY fiscal_year
)

SELECT

    *,

    LAG(sales)
    OVER (
        ORDER BY fiscal_year
    ) AS previous_year,

    ROUND(

        (
            sales -
            LAG(sales)
            OVER (
                ORDER BY fiscal_year
            )
        )

        * 100

        /

        LAG(sales)
        OVER (
            ORDER BY fiscal_year
        ),

        2

    ) AS growth_pct

FROM yearly_sales;



-- ==========================================================
-- QUERY 4 : Market Share
-- ==========================================================

SELECT

    market,

    SUM(net_sales) AS total_sales,

    ROUND(

        SUM(net_sales)

        * 100

        /

        SUM(SUM(net_sales))
        OVER(),

        2

    ) AS market_share

FROM net_sales

GROUP BY market;



-- ==========================================================
-- QUERY 5 : Customer Contribution Percentage (FY 2011)
-- ==========================================================

WITH customer_sales AS
(

    SELECT

        c.customer_name,

        ROUND(
            SUM(n.net_sales) / 1000000,
            2
        ) AS net_sales_mln

    FROM net_sales n

    JOIN dim_customer c
        ON n.customer_code = c.customer_code

    WHERE n.fiscal_year = 2011

    GROUP BY c.customer_name

)

SELECT

    *,

    ROUND(

        (
            net_sales_mln * 100
        )

        /

        SUM(net_sales_mln)
        OVER(),

        2

    ) AS contribution_pct

FROM customer_sales

ORDER BY contribution_pct DESC;



-- ==========================================================
-- QUERY 6 : Highest Selling Product in Each Division
-- ==========================================================

WITH sales_summary AS
(

    SELECT

        p.product_division,

        p.product_name,

        SUM(f.sold_quantity) AS total_quantity

    FROM fact_sales_monthly f

    JOIN dim_product p
        ON f.product_code = p.product_code

    GROUP BY

        p.product_division,
        p.product_name

),

ranking AS
(

    SELECT

        *,

        ROW_NUMBER()

        OVER (

            PARTITION BY product_division

            ORDER BY total_quantity DESC

        ) AS rn

    FROM sales_summary

)

SELECT *

FROM ranking

WHERE rn = 1;



-- ==========================================================
-- QUERY 7 : Top 2 Markets by Gross Sales (FY 2011)
-- ==========================================================

WITH market_sales AS
(

    SELECT

        market,

        SUM(gross_price_total) AS gross_sales

    FROM sales_pre_invoice_deduction

    WHERE fiscal_year = 2011

    GROUP BY market

),

ranking AS
(

    SELECT

        *,

        DENSE_RANK()

        OVER (

            ORDER BY gross_sales DESC

        ) AS rnk

    FROM market_sales

)

SELECT *

FROM ranking

WHERE rnk <= 2;