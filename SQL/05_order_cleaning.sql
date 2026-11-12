/* =====================================================================
   RELIANCE ORDER DATA CLEANING - NON-SELECT QUERIES ONLY
   Database : FREELANCING
   Source   : RELIANCE (raw table, never modified)
   Output   : ORDER123  (renamed from ORDER_I)
   Backup   : ORDER123_BACKUP (renamed from ORDER_123, so it does not
              clash with the main table name ORDER123)

   Only statements that build or change data are included
   (USE / DROP / CREATE / ALTER / UPDATE / DELETE).
   All look-up SELECTs and DESC are removed. Logic unchanged.
   Run top to bottom, in one pass.
   ===================================================================== */


/* =====================================================================
   STEP 1: SETUP
   ===================================================================== */

USE FREELANCING;

DROP TABLE IF EXISTS ORDERS;

CREATE TABLE ORDER123
SELECT
    SRC_ID, TransactionID,
    OrderID, OrderDate, DELIVERYDATE, DELIVERYDAYS, OrderTime, FinancialYear, Quarter,
    CustomerID, ProductID, Brand, ProcessorModel, GraphicsCard, LaunchYear, MRP,
    Quantity, UnitPrice, DiscountPercent, DiscountAmount, TaxableAmount, GSTPercent, GSTAmount, InvoiceAmount,
    PaymentMethod, EMITenureMonths, EMIAmountPerMonth, OrderStatus, ChannelType, StoreID
FROM RELIANCE;

/* =====================================================================
   STEP 4: GLOBAL TEXT CLEANING
   ===================================================================== */

UPDATE ORDER123
SET
    TransactionID     = NULLIF(UPPER(REGEXP_REPLACE(TRIM(TransactionID), ' +', ' ')), ''),
    OrderID           = NULLIF(UPPER(REGEXP_REPLACE(TRIM(OrderID), ' +', ' ')), ''),
    OrderDate         = NULLIF(REGEXP_REPLACE(TRIM(OrderDate), ' +', ' '), ''),
    DELIVERYDATE      = NULLIF(REGEXP_REPLACE(TRIM(DELIVERYDATE), ' +', ' '), ''),
    DELIVERYDAYS      = NULLIF(REGEXP_REPLACE(TRIM(DELIVERYDAYS), ' +', ' '), ''),
    OrderTime         = NULLIF(REGEXP_REPLACE(TRIM(OrderTime), ' +', ' '), ''),
    FinancialYear     = NULLIF(UPPER(REGEXP_REPLACE(TRIM(FinancialYear), ' +', ' ')), ''),
    Quarter           = NULLIF(UPPER(REGEXP_REPLACE(TRIM(Quarter), ' +', ' ')), ''),
    CustomerID        = NULLIF(UPPER(REGEXP_REPLACE(TRIM(CustomerID), ' +', ' ')), ''),
    ProductID         = NULLIF(UPPER(REGEXP_REPLACE(TRIM(ProductID), ' +', ' ')), ''),
    Brand             = NULLIF(UPPER(REGEXP_REPLACE(TRIM(Brand), ' +', ' ')), ''),
    ProcessorModel    = NULLIF(UPPER(REGEXP_REPLACE(TRIM(ProcessorModel), ' +', ' ')), ''),
    GraphicsCard      = NULLIF(UPPER(REGEXP_REPLACE(TRIM(GraphicsCard), ' +', ' ')), ''),
    LaunchYear        = NULLIF(REGEXP_REPLACE(TRIM(LaunchYear), ' +', ' '), ''),
    MRP               = NULLIF(REGEXP_REPLACE(TRIM(MRP), ' +', ' '), ''),
    Quantity          = NULLIF(REGEXP_REPLACE(TRIM(Quantity), ' +', ' '), ''),
    UnitPrice         = NULLIF(REGEXP_REPLACE(TRIM(UnitPrice), ' +', ' '), ''),
    DiscountPercent   = NULLIF(REGEXP_REPLACE(TRIM(DiscountPercent), ' +', ' '), ''),
    DiscountAmount    = NULLIF(REGEXP_REPLACE(TRIM(DiscountAmount), ' +', ' '), ''),
    TaxableAmount     = NULLIF(REGEXP_REPLACE(TRIM(TaxableAmount), ' +', ' '), ''),
    GSTPercent        = NULLIF(REGEXP_REPLACE(TRIM(GSTPercent), ' +', ' '), ''),
    GSTAmount         = NULLIF(REGEXP_REPLACE(TRIM(GSTAmount), ' +', ' '), ''),
    InvoiceAmount     = NULLIF(REGEXP_REPLACE(TRIM(InvoiceAmount), ' +', ' '), ''),
    PaymentMethod     = NULLIF(UPPER(REGEXP_REPLACE(TRIM(PaymentMethod), ' +', ' ')), ''),
    EMITenureMonths   = NULLIF(REGEXP_REPLACE(TRIM(EMITenureMonths), ' +', ' '), ''),
    EMIAmountPerMonth = NULLIF(REGEXP_REPLACE(TRIM(EMIAmountPerMonth), ' +', ' '), ''),
    OrderStatus       = NULLIF(UPPER(REGEXP_REPLACE(TRIM(OrderStatus), ' +', ' ')), ''),
    ChannelType       = NULLIF(UPPER(REGEXP_REPLACE(TRIM(ChannelType), ' +', ' ')), ''),
    StoreID           = NULLIF(UPPER(REGEXP_REPLACE(TRIM(StoreID), ' +', ' ')), '');


-- 2.3 UPDATE: keep only digits and '.', trim spaces, convert empty strings to NULL
UPDATE ORDER123 SET
    MRP               = NULLIF(TRIM(REGEXP_REPLACE(MRP, '[^0-9.]', '')), ''),
    UnitPrice         = NULLIF(TRIM(REGEXP_REPLACE(UnitPrice, '[^0-9.]', '')), ''),
    QUANTITY          = NULLIF(TRIM(REGEXP_REPLACE(QUANTITY, '[^0-9.]', '')), ''),
    DiscountAmount    = NULLIF(TRIM(REGEXP_REPLACE(DiscountAmount, '[^0-9.]', '')), ''),
    DiscountPercent   = NULLIF(TRIM(REGEXP_REPLACE(DiscountPercent, '[^0-9.]', '')), ''),
    TaxableAmount     = NULLIF(TRIM(REGEXP_REPLACE(TaxableAmount, '[^0-9.]', '')), ''),
    GSTAmount         = NULLIF(TRIM(REGEXP_REPLACE(GSTAmount, '[^0-9.]', '')), ''),
    InvoiceAmount     = NULLIF(TRIM(REGEXP_REPLACE(InvoiceAmount, '[^0-9.]', '')), ''),
    EMIAmountPerMonth = NULLIF(TRIM(REGEXP_REPLACE(EMIAmountPerMonth, '[^0-9.]', '')), '');

-- 3.2 UPDATE: remove the stray leading '.' from MRP
UPDATE ORDER123
SET MRP = REPLACE(MRP, '.', '')
WHERE MRP REGEXP '^\\.[0-9]+$';

-- 3.4 UPDATE: remove the stray leading '.' from UnitPrice
UPDATE ORDER123
SET UnitPrice = REPLACE(UnitPrice, '.', '')
WHERE UnitPrice REGEXP '^\\.[0-9]+$';


-- 5.4 UPDATE: cap UnitPrice at MRP
UPDATE ORDER123 SET UnitPrice = MRP WHERE UnitPrice > MRP;

-- 5.6 UPDATE: replace the 999 placeholder with the MRP
UPDATE ORDER123 SET UnitPrice = MRP WHERE UnitPrice = 999;

-- 6.2 UPDATE: replace Quantity = 500 with the lowest companion quantity
UPDATE ORDER123 t1
JOIN (
    SELECT orderid, MIN(quantity) AS alternative_quantity
    FROM ORDER123
    WHERE quantity <> 500
    GROUP BY orderid
) t2 ON t1.orderid = t2.orderid
SET t1.quantity = t2.alternative_quantity
WHERE t1.quantity = 500
  AND t1.orderstatus <> 'Delivered';
  
  -- 7.6 UPDATE: replace the 150 placeholder with the real percentage
UPDATE ORDER123
SET DiscountPercent = CASE
        WHEN (UnitPrice * Quantity) > 0
             AND ((DiscountAmount / (UnitPrice * Quantity)) * 100) >= 100.00
             THEN 50
        WHEN (UnitPrice * Quantity) > 0
             THEN ROUND(((DiscountAmount / (UnitPrice * Quantity)) * 100), 0)
        ELSE 0
    END
WHERE DiscountPercent = 150
  AND CASE
        WHEN (UnitPrice * Quantity) > 0
        THEN ROUND(((DiscountAmount / (UnitPrice * Quantity)) * 100), 2)
        ELSE 0
      END != 25.00;
      
-- needs to be reviewed

UPDATE ORDER123 SET DiscountPercent = 50 WHERE DiscountPercent = 999;

UPDATE ORDER123
SET DiscountAmount = ROUND(Quantity*UnitPrice*DiscountPercent/100, 2),
    TaxableAmount  = ROUND(Quantity*UnitPrice - ROUND(Quantity*UnitPrice*DiscountPercent/100, 2), 2)
WHERE DiscountPercent = 50 AND InvoiceAmount <= 0;

UPDATE ORDER123 SET GSTAmount = ROUND(TaxableAmount*GSTPercent/100, 2) WHERE InvoiceAmount <= 0;
UPDATE ORDER123 SET InvoiceAmount = ROUND(TaxableAmount + GSTAmount, 2) WHERE InvoiceAmount <= 0;
-- 7.8 UPDATE: add 0 where discount percent and amount are both NULL
UPDATE ORDER123
SET
    DiscountPercent = 0,
    DiscountAmount = 0
WHERE DiscountPercent IS NULL
  AND DiscountAmount IS NULL;
  
  -- 12.4 UPDATE: set EMI details for Quantity = 0 rows
UPDATE ORDER123
SET EmiAmountPerMonth = 0,
    EmiTenureMonths   = 0
WHERE Quantity = 0;


UPDATE ORDER123 o
JOIN RELIANCE r ON o.OrderID = r.OrderID
SET o.EMITenureMonths = r.EMITenureMonths,
    o.EMIAmountPerMonth = r.EMIAmountPerMonth
WHERE o.PaymentMethod LIKE 'EMI%' 
  AND IFNULL(o.EMITenureMonths, 0) = 0
  AND o.Quantity > 0;

UPDATE ORDER123
SET EMIAmountPerMonth = CASE 
        WHEN EMITenureMonths = 3  THEN ROUND((InvoiceAmount * 1.05) / 3, 2)
        WHEN EMITenureMonths = 6  THEN ROUND((InvoiceAmount * 1.08) / 6, 2)
        WHEN EMITenureMonths = 9  THEN ROUND((InvoiceAmount * 1.11) / 9, 2)
        WHEN EMITenureMonths = 12 THEN ROUND((InvoiceAmount * 1.14) / 12, 2)
        WHEN EMITenureMonths = 18 THEN ROUND((InvoiceAmount * 1.21) / 18, 2)
        WHEN EMITenureMonths = 24 THEN ROUND((InvoiceAmount * 1.28) / 24, 2)
        ELSE ROUND(InvoiceAmount / EMITenureMonths, 2)
    END
WHERE PaymentMethod LIKE 'EMI%' 
  AND Quantity > 0
  AND ABS(((EMIAmountPerMonth * EMITenureMonths) - InvoiceAmount) / InvoiceAmount) > 0.20;

UPDATE ORDER123
SET InvoiceAmount = ROUND(EMIAmountPerMonth * EMITenureMonths, 2)
WHERE PaymentMethod LIKE 'EMI%'
  AND InvoiceAmount > 1000000 
  AND EMIAmountPerMonth < 50000;

UPDATE ORDER123
SET EMIAmountPerMonth = ROUND(InvoiceAmount / EMITenureMonths, 2)
WHERE PaymentMethod LIKE 'EMI%'
  AND EMITenureMonths > 0
  AND ABS(((EMIAmountPerMonth * EMITenureMonths) - InvoiceAmount) / InvoiceAmount) > 0.20;


-- 12.6 UPDATE: set Quantity = 1 where it is 0
UPDATE ORDER123
SET Quantity = 1
WHERE Quantity = 0;

/* =====================================================================
   STEP 6: CLEAN DELIVERYDAYS
   ===================================================================== */

UPDATE ORDER123
SET DELIVERYDAYS = NULL
WHERE DELIVERYDAYS = 450;

/* =====================================================================
   STEP 7: STANDARDISE DELIVERYDATE TO YYYY-MM-DD
   ===================================================================== */

UPDATE ORDER123
SET DELIVERYDATE = CASE
    -- 1. Already ISO (YYYY-MM-DD, with or without time)
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
        THEN DATE(TRIM(DELIVERYDATE))

    -- 2. Dots: 26.02.2026
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$'
        THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d.%m.%Y'))

    -- 3. Dashes: 26-02-2026
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
        THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d-%m-%Y'))

    -- 4. Full month name: 26 February 2026
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{1,2} [A-Za-z]+ [0-9]{4}$'
        THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d %M %Y'))

    -- 5. DD-MM-YYYY + time with seconds
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}$'
        THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d-%m-%Y %H:%i:%s'))

    -- 6. DD-MM-YYYY + time without seconds
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}$'
        THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d-%m-%Y %H:%i'))

    -- 7. Slashes: DD/MM/YYYY or MM/DD/YYYY (first part > 12 can only be the day)
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN
        CASE
            WHEN CAST(SUBSTRING_INDEX(TRIM(DELIVERYDATE), '/', 1) AS UNSIGNED) > 12
                THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d/%m/%Y'))
            ELSE DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%m/%d/%Y'))
        END

    -- 8. Short month and 2-digit year: 23-Aug-25
    WHEN TRIM(DELIVERYDATE) REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$'
        THEN DATE(STR_TO_DATE(TRIM(DELIVERYDATE), '%d-%b-%y'))

    -- Unrecognised format
    ELSE NULL
END
WHERE DELIVERYDATE IS NOT NULL;

/* =====================================================================
   STEP 8: RECALCULATE DELIVERYDAYS FROM THE DATES
   ===================================================================== */

UPDATE ORDER123
SET DELIVERYDAYS = DATEDIFF(DELIVERYDATE, ORDERDATE)
WHERE DATEDIFF(DELIVERYDATE, ORDERDATE) BETWEEN 0 AND 7
  AND (DELIVERYDAYS IS NULL OR DELIVERYDAYS <> DATEDIFF(DELIVERYDATE, ORDERDATE));

/* =====================================================================
   STEP 9: BUSINESS RULES BY ORDER STATUS
   ===================================================================== */

-- Nothing is delivered for cancelled or processing orders
UPDATE ORDER123
SET DeliveryDate = NULL,
    DeliveryDays = NULL
WHERE OrderStatus IN ('CANCELLED', 'PROCESSING');

-- In-store sales: delivery date = order date, days = 0
UPDATE ORDER123
SET DeliveryDate = OrderDate,
    DeliveryDays = 0
WHERE ChannelType = 'OFFLINE - STORE'
  AND OrderStatus = 'DELIVERED'
  AND DeliveryDate IS NULL
  AND DeliveryDays IS NULL;
  
  -- Relabel orders that were CANCELLED and RETURNED but never DELIVERED
UPDATE ORDER123 AS r
JOIN (
    SELECT OrderID
    FROM ORDER123
    GROUP BY OrderID
    HAVING SUM(CASE WHEN OrderStatus = 'CANCELLED' THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN OrderStatus = 'RETURNED'  THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN OrderStatus = 'DELIVERED' THEN 1 ELSE 0 END) = 0
) AS target_orders ON r.OrderID = target_orders.OrderID
SET r.OrderStatus = 'PREDELIVERY CANCELLATION'
WHERE r.OrderStatus IN ('CANCELLED', 'RETURNED', 'PROCESSING');

-- Fill missing delivery date from OrderDate + DeliveryDays
UPDATE ORDER123
SET deliverydate = DATE_ADD(orderdate, INTERVAL deliverydays DAY)
WHERE OrderStatus = 'PREDELIVERY CANCELLATION'
  AND deliverydate IS NULL
  AND deliverydays IS NOT NULL
  AND deliverydays > 0;
  
  /* =====================================================================
   STEP 11: FILL REMAINING MISSING DELIVERY DATES
   ===================================================================== */

-- Delivered orders with no delivery info at all: same-day delivery
UPDATE ORDER123
SET DeliveryDate = OrderDate,
    DeliveryDays = 0
WHERE OrderStatus = 'DELIVERED'
  AND DeliveryDate IS NULL
  AND DeliveryDays IS NULL
  AND OrderDate IS NOT NULL;

-- DELIVERED orders with DeliveryDays but no DeliveryDate
UPDATE ORDER123
SET deliverydate = DATE_ADD(orderdate, INTERVAL deliverydays DAY)
WHERE OrderStatus = 'DELIVERED'
  AND deliverydate IS NULL
  AND deliverydays IS NOT NULL
  AND deliverydays >= 0;
  
  -- RETURNED orders with DeliveryDays but no DeliveryDate
UPDATE ORDER123
SET deliverydate = DATE_ADD(orderdate, INTERVAL deliverydays DAY)
WHERE OrderStatus = 'RETURNED'
  AND deliverydate IS NULL
  AND deliverydays IS NOT NULL
  AND deliverydays >= 0;
  
  /* =====================================================================
   STEP 12: FINANCIAL YEAR AND QUARTER FROM ORDERDATE
   (Indian financial year: April to March)
   ===================================================================== */

UPDATE ORDER123
SET FinancialYear = CASE
    WHEN MONTH(OrderDate) IN (1, 2, 3)
        THEN CONCAT('FY', YEAR(OrderDate) - 1, '-', RIGHT(YEAR(OrderDate), 2))
    ELSE CONCAT('FY', YEAR(OrderDate), '-', RIGHT(YEAR(OrderDate) + 1, 2))
END
WHERE OrderDate IS NOT NULL;

UPDATE ORDER123
SET Quarter = CONCAT('Q', QUARTER(DATE_SUB(OrderDate, INTERVAL 3 MONTH)))
WHERE OrderDate IS NOT NULL;


/* =====================================================================
   STEP 13: DROP UNNEEDED COLUMNS, FIX DATES, STANDARDISE PAYMENT METHOD
   ===================================================================== */

ALTER TABLE ORDER123
    DROP COLUMN TRANSACTIONID,
    DROP COLUMN PROCESSORMODEL,
    DROP COLUMN GRAPHICSCARD,
    DROP COLUMN LAUNCHYEAR;

-- ========================================== 9-10-26
UPDATE ORDER123
SET DELIVERYDATE = DATE_ADD(ORDERDATE, INTERVAL DELIVERYDAYS DAY)
WHERE DELIVERYDATE < ORDERDATE;

UPDATE ORDER123
SET DELIVERYDATE = DATE_ADD(ORDERDATE, INTERVAL DELIVERYDAYS DAY)
WHERE ORDERDATE IS NOT NULL
  AND DELIVERYDAYS IS NOT NULL;

UPDATE ORDER123
SET PaymentMethod = CASE REPLACE(REPLACE(UPPER(TRIM(PaymentMethod)),' ',''),'-','')
        WHEN 'EMICREDITCARD'             THEN 'EMI - Credit Card'
        WHEN 'EMINOCOST'                 THEN 'EMI - No Cost'
        WHEN 'CREDITCARD'                THEN 'Credit Card'
        WHEN 'DEBITCARD'                 THEN 'Debit Card'
        WHEN 'NETBANKING'                THEN 'Net Banking'
        WHEN 'UPI'                       THEN 'UPI'
        WHEN 'CASH'                      THEN 'Cash'
        WHEN 'RELIANCEDIGITALGIFTCARD'   THEN 'Reliance Digital Gift Card'
        ELSE PaymentMethod
    END
WHERE PaymentMethod IS NOT NULL;


-- 8.2 UPDATE: recalculate Discount Amount
UPDATE ORDER123 SET DiscountAmount = ROUND(Quantity * UnitPrice * DiscountPercent / 100, 2);

-- 8.4 UPDATE: recalculate Taxable Amount
UPDATE ORDER123 SET TaxableAmount = ROUND((Quantity * UnitPrice) - DiscountAmount, 2);

-- 8.6 UPDATE: standardise GST percent to 18
UPDATE ORDER123 SET GSTPERCENT = 18 WHERE GSTPERCENT != 18;

-- 8.8 UPDATE: recalculate GST Amount
UPDATE ORDER123 SET GSTAmount = ROUND(TaxableAmount * GSTPercent / 100, 2);

-- 8.10 UPDATE: recalculate final Invoice Amount
UPDATE ORDER123 SET InvoiceAmount = ROUND(TaxableAmount + GSTAmount, 2);

-- Tenure from amount
UPDATE ORDER123
SET EMITenureMonths = ROUND(InvoiceAmount / EMIAmountPerMonth)
WHERE PaymentMethod LIKE '%EMI%' AND EMIAmountPerMonth > 0 AND IFNULL(EMITenureMonths,0) = 0;



-- Amount from tenure
UPDATE ORDER123
SET EMIAmountPerMonth = ROUND(InvoiceAmount / EMITenureMonths, 2)
WHERE PaymentMethod LIKE 'EMI%' AND EMITenureMonths > 0 AND IFNULL(EMIAmountPerMonth,0) = 0;

-- same as case when results
-- SET EMITenureMonths = ELT(1 + (ROUND(InvoiceAmount/EMIAmountPerMonth) >= 4) + 
-- (ROUND(InvoiceAmount/EMIAmountPerMonth) >= 8) + (ROUND(InvoiceAmount/EMIAmountPerMonth) >= 11), 3, 6, 9, 12)

UPDATE ORDER123
SET EMITenureMonths = CASE
        WHEN ROUND(InvoiceAmount / EMIAmountPerMonth) >= 11 THEN 12
        WHEN ROUND(InvoiceAmount / EMIAmountPerMonth) >= 8  THEN 9
        WHEN ROUND(InvoiceAmount / EMIAmountPerMonth) >= 4  THEN 6
        ELSE 3
    END
WHERE PaymentMethod LIKE 'EMI%'
  AND EMIAmountPerMonth > 0
  AND IFNULL(EMITenureMonths, 0) = 0;

-- 4.1 PREVIEW: current column data types before changing them
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ORDER123';

ALTER TABLE ORDER123
    MODIFY COLUMN MRP               DECIMAL(20,2),
    MODIFY COLUMN Quantity          INT,
    MODIFY COLUMN UnitPrice         DECIMAL(20,2),
    MODIFY COLUMN DiscountPercent   DECIMAL(5,2),
    MODIFY COLUMN DiscountAmount    DECIMAL(20,2),
    MODIFY COLUMN TaxableAmount     DECIMAL(20,2),
    MODIFY COLUMN GSTPercent        DECIMAL(5,2),
    MODIFY COLUMN GSTAmount         DECIMAL(20,2),
    MODIFY COLUMN InvoiceAmount     DECIMAL(20,2),
    MODIFY COLUMN EMITenureMonths   INT,
    MODIFY COLUMN EMIAmountPerMonth DECIMAL(20,2);
/* =====================================================================
   STEP 14: REMOVE DUPLICATES
   ===================================================================== */

-- Delete exact duplicates, keeping the lowest SRC_ID in each group
DELETE FROM ORDER123
WHERE SRC_ID NOT IN (
    SELECT MIN(SRC_ID)
    FROM (
        SELECT
            SRC_ID, OrderID, OrderDate, DELIVERYDATE, DELIVERYDAYS, OrderTime,
            FinancialYear, Quarter, CustomerID, ProductID, Brand,
            MRP, Quantity, UnitPrice, DiscountPercent, DiscountAmount,
            TaxableAmount, GSTPercent, GSTAmount, InvoiceAmount, PaymentMethod,
            EmiTenureMonths, EMIAmountPerMonth, OrderStatus, ChannelType, StoreID
        FROM ORDER123
    ) AS STR
    GROUP BY
        OrderID, OrderDate, DELIVERYDATE, DELIVERYDAYS, OrderTime,
        FinancialYear, Quarter, CustomerID, ProductID, Brand,
        MRP, Quantity, UnitPrice, DiscountPercent, DiscountAmount,
        TaxableAmount, GSTPercent, GSTAmount, InvoiceAmount, PaymentMethod,
        EmiTenureMonths, EMIAmountPerMonth, OrderStatus, ChannelType, StoreID
);

-- Refresh the backup snapshot (ORDER_123 renamed to ORDER123_BACKUP)
DROP TABLE ORDER123_BACKUP;
CREATE TABLE ORDER123_BACKUP SELECT * FROM ORDER123;

-- Keep one row per OrderID, preferring RETURNED > CANCELLED > DELIVERED > PREDELIVERED
DELETE o
FROM ORDER123 o
JOIN (SELECT SRC_ID,ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY CASE OrderStatus
                          WHEN 'RETURNED'     THEN 1
                          WHEN 'CANCELLED'    THEN 2
                          WHEN 'DELIVERED'    THEN 3
                          WHEN 'PREDELIVERED' THEN 4
                          ELSE 5 END,
                        SRC_ID DESC) AS rn FROM ORDER123) x ON x.SRC_ID = o.SRC_ID WHERE x.rn > 1;
                        
                        