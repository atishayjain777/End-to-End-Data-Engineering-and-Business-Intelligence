
-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Functions.sql
-- Description  : Creates User Defined Functions (UDFs)
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- FUNCTION 1 : get_fiscal_year
-- ==========================================================

DROP FUNCTION IF EXISTS get_fiscal_year;

DELIMITER $$

CREATE FUNCTION get_fiscal_year(
    calendar_date DATE
)
RETURNS INT
DETERMINISTIC
BEGIN

    DECLARE fiscal_year INT;

    SET fiscal_year = YEAR(
        DATE_ADD(calendar_date, INTERVAL 9 MONTH)
    );

    RETURN fiscal_year;

END$$

DELIMITER ;



-- ==========================================================
-- FUNCTION 2 : get_fiscal_year_quarter
-- ==========================================================

DROP FUNCTION IF EXISTS get_fiscal_year_quarter;

DELIMITER $$

CREATE FUNCTION get_fiscal_year_quarter(
    calendar_date DATE
)
RETURNS CHAR(2)
DETERMINISTIC
BEGIN

    DECLARE fiscal_quarter CHAR(2);

    CASE
        WHEN MONTH(calendar_date) IN (4,5,6)
            THEN SET fiscal_quarter = 'Q1';

        WHEN MONTH(calendar_date) IN (7,8,9)
            THEN SET fiscal_quarter = 'Q2';

        WHEN MONTH(calendar_date) IN (10,11,12)
            THEN SET fiscal_quarter = 'Q3';

        ELSE
            SET fiscal_quarter = 'Q4';
    END CASE;

    RETURN fiscal_quarter;

END$$

DELIMITER ;