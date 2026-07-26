-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Stored_Procedures.sql
-- Description  : Creates all Stored Procedures
-- Database     : global_estore
-- ==========================================================




-- ==========================================================
-- STORED PROCEDURE 1 : get_forecast_accuracy
-- ==========================================================




DELIMITER $$

CREATE PROCEDURE get_forecast_accuracy(
    IN in_fiscal_year INT
)

BEGIN

WITH forecast_error AS
(
    SELECT

        h.customer_code,

        SUM(h.forecast_quantity-h.sold_quantity) AS net_error,

        SUM(ABS(h.forecast_quantity-h.sold_quantity))
        AS absolute_net_error,

        ROUND(
        SUM(h.forecast_quantity-h.sold_quantity)*100/
        NULLIF(SUM(h.forecast_quantity),0),2
        ) AS net_error_pct,

        ROUND(
        SUM(ABS(h.forecast_quantity-h.sold_quantity))*100/
        NULLIF(SUM(h.forecast_quantity),0),2
        ) AS abs_error_pct

    FROM helper_clean h

    WHERE h.fiscal_year=in_fiscal_year

    GROUP BY h.customer_code
)

SELECT

    f.customer_code,

    c.customer_name,

    f.net_error,

    f.absolute_net_error,

    f.net_error_pct,

    f.abs_error_pct,

    ROUND(
    GREATEST(0,100-f.abs_error_pct),
    2
    ) AS forecast_accuracy

FROM forecast_error f

JOIN dim_customer c

ON f.customer_code=c.customer_code

ORDER BY forecast_accuracy DESC;

END$$

DELIMITER ;







-- ==========================================================
-- STORED PROCEDURE 2 : get_market_badge
-- ==========================================================


DELIMITER $$

CREATE PROCEDURE get_market_badge(

    IN in_market VARCHAR(45),

    IN in_fiscal_year INT,

    OUT out_badge VARCHAR(20)

)

BEGIN

DECLARE qty INT DEFAULT 0;

IF in_market IS NULL
OR TRIM(in_market)='' THEN

SET in_market='India';

END IF;

SELECT

SUM(s.sold_quantity)

INTO qty

FROM fact_sales_monthly s

WHERE s.market=in_market

AND get_fiscal_year(s.sales_month)=in_fiscal_year;

IF qty>26000 THEN

SET out_badge='Gold';

ELSE

SET out_badge='Silver';

END IF;

END$$

DELIMITER ;





-- ==========================================================
-- STORED PROCEDURE 3: get_monthly_gross_sales_for_customers.sql
-- ==========================================================



DELIMITER $$

CREATE PROCEDURE get_monthly_gross_sales_for_customers(

    IN in_customer_codes TEXT

)

BEGIN

SELECT

    f.sales_month,

    ROUND(

    SUM(g.gross_price*f.sold_quantity),

    2

    ) AS gross_sales

FROM fact_sales_monthly f

JOIN gross_price g

ON f.product_code=g.product_code

AND f.customer_code=g.customer_code

AND f.sales_month=g.sales_month

AND f.market=g.market

AND f.region=g.region

AND f.sub_zone=g.sub_zone

WHERE FIND_IN_SET(

f.customer_code,

in_customer_codes

)>0

GROUP BY

f.sales_month

ORDER BY

f.sales_month;

END$$

DELIMITER ;






-- ==========================================================
-- STORED PROCEDURE 4: get_top_products_by_division.sql
-- ==========================================================


DELIMITER $$

CREATE PROCEDURE get_top_products_by_division(

    IN in_fiscal_year INT,
    IN in_top_n INT

)

BEGIN
(
WITH product_sales AS
(
    SELECT

        p.product_division,

        p.product_name,

        SUM(f.sold_quantity) AS total_quantity

    FROM fact_sales_monthly f

    JOIN dim_product p
        ON f.product_code = p.product_code

    WHERE get_fiscal_year(f.sales_month) = in_fiscal_year

    GROUP BY
        p.product_division,
        p.product_name
),

ranking AS
(
    SELECT

        *,

        DENSE_RANK() OVER(
            PARTITION BY product_division
            ORDER BY total_quantity DESC
        ) AS product_rank

    FROM product_sales
)

SELECT *

FROM ranking

WHERE product_rank <= in_top_n

ORDER BY
    product_division,
    product_rank;

END$$

DELIMITER ;





-- ==========================================================
-- STORED PROCEDURE 5: top_customers_by_net_sales.sql
-- ==========================================================



DELIMITER $$

CREATE PROCEDURE top_customers_by_net_sales(

    IN in_fiscal_year INT,
    IN in_market VARCHAR(30),
    IN in_top_n INT

)

BEGIN

SELECT

    c.customer_name,

    ROUND(
        SUM(n.net_sales)/1000000,
        2
    ) AS net_sales_mln

FROM net_sales n

JOIN dim_customer c
ON n.customer_code = c.customer_code

WHERE n.fiscal_year = in_fiscal_year
AND n.market = in_market

GROUP BY
    c.customer_name

ORDER BY
    net_sales_mln DESC

LIMIT in_top_n;

END$$

DELIMITER ;




-- ==========================================================
-- STORED PROCEDURE 6: top_products_by_net_sales.sql
-- ==========================================================



DELIMITER $$

CREATE PROCEDURE top_products_by_net_sales(

    IN in_fiscal_year INT,
    IN in_market VARCHAR(30),
    IN in_top_n INT

)

BEGIN

SELECT

    product_name,

    ROUND(
        SUM(net_sales)/1000000,
        2
    ) AS net_sales_mln

FROM net_sales

WHERE fiscal_year = in_fiscal_year
AND market = in_market

GROUP BY
    product_name

ORDER BY
    net_sales_mln DESC

LIMIT in_top_n;

END$$

DELIMITER ;





-- ==========================================================
-- STORED PROCEDURE 6: top_markets_by_net_sales.sql
-- ==========================================================


DELIMITER $$

CREATE PROCEDURE top_markets_by_net_sales(

    IN in_fiscal_year INT,
    IN in_top_n INT

)

BEGIN

SELECT

    market,

    ROUND(
        SUM(net_sales)/1000000,
        2
    ) AS net_sales_mln

FROM net_sales

WHERE fiscal_year = in_fiscal_year

GROUP BY
    market

ORDER BY
    net_sales_mln DESC

LIMIT in_top_n;

END$$

DELIMITER ;









