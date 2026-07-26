-- Data_Cleaning


-- ==========================================================
-- File Name : 01_Data_Type_Conversion.sql
-- Description : Convert columns to appropriate data types
-- ==========================================================

USE global_estore_raw;

-- Convert sales_month to DATE
ALTER TABLE helper_clean
MODIFY sales_month DATE;

-- Convert sold_quantity
ALTER TABLE helper_clean
MODIFY sold_quantity INT;

-- Convert forecast quantity
ALTER TABLE fact_forecast
MODIFY forecast_quantity DECIMAL(12,2);

-- Convert gross price
ALTER TABLE gross_price
MODIFY gross_price DECIMAL(12,2);

-- Convert manufacturing cost
ALTER TABLE manufacturing_cost
MODIFY manufacturing_cost DECIMAL(12,2);

-- Convert freight percentage
ALTER TABLE freight_cost
MODIFY freight_pct DECIMAL(8,2);





📂 02_Text_Standardization.sql

-- ==========================================================
-- File Name : 02_Text_Standardization.sql
-- Description : Standardize text columns
-- ==========================================================

USE global_estore_raw;

UPDATE dim_customer
SET customer = TRIM(customer);

UPDATE dim_product
SET product = TRIM(product);

UPDATE dim_market
SET market = TRIM(market);

UPDATE dim_market
SET region = TRIM(region);

UPDATE dim_market
SET country = TRIM(country);

UPDATE dim_product
SET category = UPPER(category);

UPDATE dim_market
SET market = UPPER(market);

UPDATE dim_market
SET region = UPPER(region);


📂 03_Date_Standardization.sql


-- ==========================================================
-- File Name : 03_Date_Standardization.sql
-- Description : Standardize date values
-- ==========================================================

USE global_estore_raw;

SELECT
sales_month,
MONTHNAME(sales_month) AS month_name,
QUARTER(sales_month) AS quarter_no,
YEAR(DATE_ADD(sales_month,INTERVAL 4 MONTH)) AS fiscal_year
FROM helper_clean;



📂 04_Data_Normalization.sql


-- ==========================================================
-- File Name : 04_Data_Normalization.sql
-- Description : Normalize business values
-- ==========================================================

USE global_estore_raw;

UPDATE dim_market
SET market='APAC'
WHERE market='Asia Pacific';

UPDATE dim_market
SET market='EU'
WHERE market='Europe';

UPDATE dim_market
SET market='LATAM'
WHERE market='Latin America';


RENAME TABLE fright_cost TO freight_cost;




📂 05_Business_Rule_Transformation.sql


-- ==========================================================
-- File Name : 05_Business_Rule_Transformation.sql
-- Description : Apply business calculations
-- ==========================================================

USE global_estore_raw;

SELECT
hc.customer_code,
hc.product_code,
hc.sales_month,
hc.sold_quantity,
gp.gross_price,
(hc.sold_quantity * gp.gross_price) AS gross_sales
FROM helper_clean hc
JOIN gross_price gp
ON hc.product_code = gp.product_code;


06_String_Format_Cleanup.sql
-- ==========================================================
-- File Name : 06_String_Format_Cleanup.sql
-- Description : Apply business calculations
-- ==========================================================


UPDATE dim_customer
SET customer = REPLACE(customer, '  ', ' ');

UPDATE dim_product
SET product = TRIM(product);
