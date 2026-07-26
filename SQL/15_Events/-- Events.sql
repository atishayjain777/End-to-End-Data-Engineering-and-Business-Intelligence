-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Events.sql
-- Description  : MySQL Event Scheduler for Automation
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- Enable Event Scheduler
-- ==========================================================

SHOW VARIABLES LIKE 'event_scheduler';

SET GLOBAL event_scheduler = ON;



-- ==========================================================
-- EVENT 1 : Refresh Forecast Accuracy Every Month
-- ==========================================================

DROP EVENT IF EXISTS ev_refresh_forecast;

CREATE EVENT ev_refresh_forecast

ON SCHEDULE EVERY 1 MONTH

DO

CALL get_forecast_accuracy();



-- ==========================================================
-- TABLE : Data Profile Log
-- ==========================================================

DROP TABLE IF EXISTS data_profile_log;

CREATE TABLE data_profile_log
(
    log_date DATE,

    total_rows INT,

    customers INT,

    products INT
);



-- ==========================================================
-- EVENT 2 : Monthly Data Profile Snapshot
-- ==========================================================

DROP EVENT IF EXISTS ev_data_profile;

CREATE EVENT ev_data_profile

ON SCHEDULE EVERY 1 MONTH

DO

INSERT INTO data_profile_log

SELECT

    CURDATE(),

    COUNT(*) AS total_rows,

    COUNT(DISTINCT customer_code) AS customers,

    COUNT(DISTINCT product_code) AS products

FROM fact_sales_monthly;



-- ==========================================================
-- TABLE : Duplicate Record Log
-- ==========================================================

DROP TABLE IF EXISTS duplicate_log;

CREATE TABLE duplicate_log
(
    log_date DATE,

    duplicate_rows INT
);



-- ==========================================================
-- EVENT 3 : Monthly Duplicate Record Check
-- ==========================================================

DROP EVENT IF EXISTS ev_duplicate_check;

CREATE EVENT ev_duplicate_check

ON SCHEDULE EVERY 1 MONTH

DO

INSERT INTO duplicate_log

SELECT

    CURDATE(),

    COUNT(*)

FROM
(
    SELECT

        customer_code,

        product_code,

        sales_month,

        COUNT(*) AS cnt

    FROM fact_sales_monthly

    GROUP BY

        customer_code,
        product_code,
        sales_month

    HAVING COUNT(*) > 1

) x;



-- ==========================================================
-- TABLE : Session Logs
-- ==========================================================

CREATE TABLE IF NOT EXISTS random_tables.session_logs
(
    ts DATETIME,

    session_id INT,

    user_id INT,

    log TEXT
);



INSERT INTO random_tables.session_logs
(
    ts,
    session_id,
    user_id,
    log
)
VALUES

('2022-10-04 08:14:07',898812,523,'CLICKED | Courses Button'),

('2022-10-14 08:18:35',898812,523,'NAVIGATE BACK | Python Course Page'),

('2022-10-16 12:07:00',965345,523,'REVIEW GENERATED | Data Analytics in Power BI'),

('2022-10-22 14:09:22',188567,707,'NEW LOGIN | tasty@jalebi.com'),

('2022-10-22 18:10:06',188567,707,'COURSE PURCHASED | Data Analytics in Power BI');



-- ==========================================================
-- EVENT 4 : Daily Session Log Cleanup
-- ==========================================================

DROP EVENT IF EXISTS e_daily_log_purge;

DELIMITER $$

CREATE EVENT e_daily_log_purge

ON SCHEDULE EVERY 1 DAY

DO

BEGIN

    DELETE

    FROM random_tables.session_logs

    WHERE ts < DATE_SUB(CURDATE(), INTERVAL 5 DAY);

END$$

DELIMITER ;



- ==========================================================
-- EVENT 5 : Weekly Database Backup Log
-- =============-=============================================




DROP TABLE IF EXISTS backup_log;

CREATE TABLE backup_log
(
    backup_date DATETIME,
    status VARCHAR(50)
);

DROP EVENT IF EXISTS ev_backup_log;

CREATE EVENT ev_backup_log

ON SCHEDULE EVERY 1 WEEK

DO

INSERT INTO backup_log

VALUES

(
    NOW(),
    'Backup Completed'
);




- ==========================================================
-- EVENT 6 : Monthly Sales Summary
-- =============-=============================================



DROP TABLE IF EXISTS monthly_sales_summary;

CREATE TABLE monthly_sales_summary
(
    summary_date DATE,
    total_sales DECIMAL(18,2)
);

DROP EVENT IF EXISTS ev_monthly_sales_summary;

CREATE EVENT ev_monthly_sales_summary

ON SCHEDULE EVERY 1 MONTH

DO

INSERT INTO monthly_sales_summary

SELECT

    CURDATE(),

    SUM(net_sales)

FROM net_sales;