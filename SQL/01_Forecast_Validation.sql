-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Forecast_Validation.sql
-- Description  : Forecast Validation & Supply Chain Analysis
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- QUERY 1 : Forecast Accuracy by Customer
-- ==========================================================

WITH forecast_error AS
(

    SELECT

        customer_code,

        SUM(forecast_quantity - sold_quantity) AS net_error,

        SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,

        ROUND(

            SUM(forecast_quantity - sold_quantity) * 100

            /

            NULLIF(SUM(forecast_quantity), 0),

            2

        ) AS net_error_pct,

        ROUND(

            SUM(ABS(forecast_quantity - sold_quantity)) * 100

            /

            NULLIF(SUM(forecast_quantity), 0),

            2

        ) AS abs_error_pct

    FROM helper_clean

    WHERE sales_month BETWEEN '2014-04-01' AND '2015-03-31'

    GROUP BY customer_code

)

SELECT

    *,

    ROUND(

        GREATEST(0, 100 - abs_error_pct),

        2

    ) AS forecast_accuracy

FROM forecast_error

ORDER BY forecast_accuracy DESC;



-- ==========================================================
-- QUERY 2 : Year-over-Year Growth
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
-- QUERY 3 : Forecast vs Actual Sales
-- ==========================================================

SELECT

    customer_code,

    SUM(sold_quantity) AS actual_sales,

    SUM(forecast_quantity) AS forecast_sales

FROM helper

GROUP BY customer_code;



-- ==========================================================
-- QUERY 4 : Forecast Bias
-- ==========================================================

SELECT

    customer_code,

    CASE

        WHEN SUM(forecast_quantity) > SUM(sold_quantity)
            THEN 'Over Forecast'

        WHEN SUM(forecast_quantity) < SUM(sold_quantity)
            THEN 'Under Forecast'

        ELSE 'Perfect Forecast'

    END AS forecast_bias

FROM helper

GROUP BY customer_code;



-- ==========================================================
-- QUERY 5 : Mean Absolute Percentage Error (MAPE)
-- ==========================================================

SELECT

    customer_code,

    ROUND(

        AVG(

            ABS(forecast_quantity - sold_quantity)

            /

            NULLIF(sold_quantity, 0)

        ) * 100,

        2

    ) AS mape

FROM helper

GROUP BY customer_code;



-- ==========================================================
-- QUERY 6 : Top 10 Best Forecast Customers
-- ==========================================================

SELECT

    customer_code,

    ROUND(

        100 -

        AVG(

            ABS(forecast_quantity - sold_quantity)

            /

            NULLIF(
                GREATEST(sold_quantity, forecast_quantity),
                0
            )

        ) * 100,

        2

    ) AS forecast_accuracy

FROM helper

GROUP BY customer_code

ORDER BY forecast_accuracy DESC

LIMIT 10;



-- ==========================================================
-- QUERY 7 : Top 10 Worst Forecast Customers
-- ==========================================================

SELECT

    customer_code,

    ROUND(

        100 -

        AVG(

            ABS(forecast_quantity - sold_quantity)

            /

            NULLIF(
                GREATEST(sold_quantity, forecast_quantity),
                0
            )

        ) * 100,

        2

    ) AS forecast_accuracy

FROM helper

GROUP BY customer_code

ORDER BY forecast_accuracy ASC

LIMIT 10;