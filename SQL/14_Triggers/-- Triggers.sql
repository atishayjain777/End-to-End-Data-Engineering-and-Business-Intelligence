-- ==========================================================
-- Project      : End-to-End Data Engineering & Business Intelligence
-- File         : 01_Triggers.sql
-- Description  : Database Triggers for Data Validation & Auditing
-- Database     : global_estore
-- ==========================================================


-- ==========================================================
-- TRIGGER 1 : Prevent Negative Sold Quantity
-- ==========================================================

DROP TRIGGER IF EXISTS trg_check_quantity;

DELIMITER $$

CREATE TRIGGER trg_check_quantity

BEFORE INSERT

ON fact_sales_monthly

FOR EACH ROW

BEGIN

    IF NEW.sold_quantity < 0 THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT = 'Sold Quantity cannot be negative';

    END IF;

END$$

DELIMITER ;



-- ==========================================================
-- TRIGGER 2 : Prevent Negative Gross Price
-- ==========================================================

DROP TRIGGER IF EXISTS trg_check_gross_price;

DELIMITER $$

CREATE TRIGGER trg_check_gross_price

BEFORE INSERT

ON gross_price

FOR EACH ROW

BEGIN

    IF NEW.gross_price < 0 THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT = 'Gross Price cannot be negative';

    END IF;

END$$

DELIMITER ;



-- ==========================================================
-- TABLE : Discount Audit Log
-- ==========================================================

DROP TABLE IF EXISTS discount_audit;

CREATE TABLE discount_audit
(
    audit_id INT AUTO_INCREMENT PRIMARY KEY,

    customer_code VARCHAR(30),

    old_discount DECIMAL(5,2),

    new_discount DECIMAL(5,2),

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- ==========================================================
-- TRIGGER 3 : Audit Discount Changes
-- ==========================================================

DROP TRIGGER IF EXISTS trg_discount_audit;

DELIMITER $$

CREATE TRIGGER trg_discount_audit

AFTER UPDATE

ON pre_invoice_deduction

FOR EACH ROW

BEGIN

    IF OLD.discount_pct <> NEW.discount_pct THEN

        INSERT INTO discount_audit
        (
            customer_code,
            old_discount,
            new_discount
        )

        VALUES
        (
            NEW.customer_code,
            OLD.discount_pct,
            NEW.discount_pct
        );

    END IF;

END$$

DELIMITER ;




- ==========================================================
    Trigger 4 : Prevent Duplicate Sales Record
-- ==========================================================



DROP TRIGGER IF EXISTS trg_prevent_duplicate_sales;

DELIMITER $$

CREATE TRIGGER trg_prevent_duplicate_sales

BEFORE INSERT

ON fact_sales_monthly

FOR EACH ROW

BEGIN

    IF EXISTS
    (
        SELECT 1

        FROM fact_sales_monthly

        WHERE customer_code = NEW.customer_code
          AND product_code = NEW.product_code
          AND sales_month = NEW.sales_month
          AND market = NEW.market
          AND region = NEW.region
          AND sub_zone = NEW.sub_zone
    )

    THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Duplicate Sales Record Found';

    END IF;

END$$

DELIMITER ;





 ==========================================================
   Trigger 5 : Prevent Invalid Discount
-- ==========================================================

DROP TRIGGER IF EXISTS trg_check_discount;

DELIMITER $$

CREATE TRIGGER trg_check_discount

BEFORE INSERT

ON pre_invoice_deduction

FOR EACH ROW

BEGIN

    IF NEW.discount_pct < 0
       OR NEW.discount_pct > 100 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Discount must be between 0 and 100 percent';

    END IF;

END$$

DELIMITER ;