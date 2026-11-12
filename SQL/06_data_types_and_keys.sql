use freelancing;

/* 2. Check for orphan records before joining
All three should return 0. If they don’t, report those rows rather than deleting them.
*/
SELECT COUNT(*) FROM ORDER_I o LEFT JOIN CUSTOMER c ON o.CUSTOMERID=c.CUSTOMERID WHERE c.CUSTOMERID IS NULL;
SELECT COUNT(*) FROM ORDER_I o LEFT JOIN PRODUCTDATA p ON o.PRODUCTID=p.PRODUCTID WHERE p.PRODUCTID IS NULL;
SELECT COUNT(*) FROM ORDER_I o LEFT JOIN STOR s ON o.STOREID=s.STOREID WHERE s.STOREID IS NULL;

-- ======================
SELECT CUSTOMERID, COUNT(*) FROM customer    GROUP BY CUSTOMERID HAVING COUNT(*) > 1;
SELECT PRODUCTID,  COUNT(*) FROM productdata GROUP BY PRODUCTID  HAVING COUNT(*) > 1;
SELECT STOREID,    COUNT(*) FROM stor        GROUP BY STOREID    HAVING COUNT(*) > 1;

SELECT SUM(CUSTOMERID IS NULL), SUM(PRODUCTID IS NULL), SUM(STOREID IS NULL) FROM order_i;

SELECT
  SUM(c.CUSTOMERID IS NULL) AS orders_without_customer,
  SUM(p.PRODUCTID  IS NULL) AS orders_without_product,
  SUM(s.STOREID    IS NULL) AS orders_without_store
FROM order_i o
LEFT JOIN customer    c ON o.CUSTOMERID = c.CUSTOMERID
LEFT JOIN productdata p ON o.PRODUCTID  = p.PRODUCTID
LEFT JOIN stor        s ON o.STOREID    = s.STOREID;


SELECT
  (SELECT COUNT(*) FROM order_i) AS orders_only,
  (SELECT COUNT(*)
   FROM order_i o
   LEFT JOIN customer    c ON o.CUSTOMERID = c.CUSTOMERID
   LEFT JOIN productdata p ON o.PRODUCTID  = p.PRODUCTID
   LEFT JOIN stor        s ON o.STOREID    = s.STOREID) AS after_left_joins,
  (SELECT COUNT(*)
   FROM order_i o
   JOIN customer    c ON o.CUSTOMERID = c.CUSTOMERID
   JOIN productdata p ON o.PRODUCTID  = p.PRODUCTID
   JOIN stor        s ON o.STOREID    = s.STOREID) AS after_inner_joins;

SELECT SUM(invoiceAMOUNT) FROM order_i;

SELECT SUM(o.invoiceAMOUNT)
FROM order_i o
LEFT JOIN customer    c ON o.CUSTOMERID = c.CUSTOMERID
LEFT JOIN productdata p ON o.PRODUCTID  = p.PRODUCTID
LEFT JOIN stor        s ON o.STOREID    = s.STOREID;

SELECT o.ORDERID, o.CUSTOMERID, c.CUSTOMERID AS c_id,
       o.PRODUCTID, p.PRODUCTID AS p_id,
       o.STOREID, s.STOREID AS s_id
FROM order_i o
LEFT JOIN customer    c ON o.CUSTOMERID = c.CUSTOMERID
LEFT JOIN productdata p ON o.PRODUCTID  = p.PRODUCTID
LEFT JOIN stor        s ON o.STOREID    = s.STOREID
LIMIT 20;
/*
CREATE OR REPLACE VIEW order_full AS
SELECT o.*, c.*, p.*, s.*
FROM order_i o
LEFT JOIN customer    c ON o.CUSTOMERID = c.CUSTOMERID
LEFT JOIN productdata p ON o.PRODUCTID  = p.PRODUCTID
LEFT JOIN stor        s ON o.STOREID    = s.STOREID;
*/

desc order_i;

/* CREATE OR REPLACE VIEW order_full AS
SELECT o.OrderID, o.OrderDate, o.DELIVERYDATE, o.DELIVERYDAYS,
       o.OrderTime, o.FinancialYear, o.Quarter,
       o.CustomerID, o.ProductID, o.StoreID,
       o.Brand, o.MRP, o.Quantity, o.UnitPrice,
       o.DiscountPercent, o.DiscountAmount, o.TaxableAmount,
       o.GSTPercent, o.GSTAmount, o.InvoiceAmount,
       o.PaymentMethod, o.EmiTenureMonths, o.EMIAmountPerMonth,
       o.OrderStatus, o.ChannelType
FROM order_i o
LEFT JOIN customer    c ON o.CustomerID = c.CustomerID
LEFT JOIN productdata p ON o.ProductID  = p.ProductID
LEFT JOIN stor        s ON o.StoreID    = s.StoreID;
*/

-- ====================================================================
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

SELECT * FROM freelancing.order_full where orderid = 'RD-ORD-569362';

SELECT COUNT(*) FROM ORDER_FULL123;
DESC RELIANCE;



-- ===================================================================================================================
-- ====================================================================================================================
-- ***************************************************************************************************************

SELECT * FROM freelancing.order_full123;

SELECT COUNT(*) FROM ORDER_FULL123;
DESC RELIANCE;
use freelancing;

select distinct brand from order_full123;
desc order_i;

-- Check if OrderID is unique per row
SELECT OrderID, COUNT(*) 
FROM order_full123
GROUP BY OrderID 
HAVING COUNT(*) > 1;

/*

SELECT
    OrderID,
    COUNT(*) AS record_count,
    CONCAT_WS(', ',
        IF(COUNT(DISTINCT COALESCE(CAST(OrderDate AS CHAR),'NULL'))         > 1, 'OrderDate', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DELIVERYDATE AS CHAR),'NULL'))      > 1, 'DELIVERYDATE', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DELIVERYDAYS AS CHAR),'NULL'))      > 1, 'DELIVERYDAYS', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(OrderTime AS CHAR),'NULL'))         > 1, 'OrderTime', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(FinancialYear AS CHAR),'NULL'))     > 1, 'FinancialYear', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(Quarter AS CHAR),'NULL'))           > 1, 'Quarter', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(CustomerID AS CHAR),'NULL'))        > 1, 'CustomerID', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(ProductID AS CHAR),'NULL'))         > 1, 'ProductID', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(Brand AS CHAR),'NULL'))             > 1, 'Brand', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(MRP AS CHAR),'NULL'))               > 1, 'MRP', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(Quantity AS CHAR),'NULL'))          > 1, 'Quantity', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(UnitPrice AS CHAR),'NULL'))         > 1, 'UnitPrice', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DiscountPercent AS CHAR),'NULL'))   > 1, 'DiscountPercent', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DiscountAmount AS CHAR),'NULL'))    > 1, 'DiscountAmount', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(TaxableAmount AS CHAR),'NULL'))     > 1, 'TaxableAmount', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(GSTPercent AS CHAR),'NULL'))        > 1, 'GSTPercent', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(GSTAmount AS CHAR),'NULL'))         > 1, 'GSTAmount', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(InvoiceAmount AS CHAR),'NULL'))     > 1, 'InvoiceAmount', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(PaymentMethod AS CHAR),'NULL'))     > 1, 'PaymentMethod', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(EmiTenureMonths AS CHAR),'NULL'))   > 1, 'EmiTenureMonths', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(EMIAmountPerMonth AS CHAR),'NULL')) > 1, 'EMIAmountPerMonth', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(OrderStatus AS CHAR),'NULL'))       > 1, 'OrderStatus', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(ChannelType AS CHAR),'NULL'))       > 1, 'ChannelType', NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(StoreID AS CHAR),'NULL'))           > 1, 'StoreID', NULL)
    ) AS differing_columns
FROM order_i
GROUP BY OrderID
HAVING COUNT(*) > 1
ORDER BY OrderID;

SELECT
    OrderID,
    COUNT(*) AS record_count,
    CONCAT_WS(' | ',
        IF(COUNT(DISTINCT COALESCE(CAST(OrderDate AS CHAR),'NULL'))         > 1, CONCAT('OrderDate=',         GROUP_CONCAT(DISTINCT COALESCE(CAST(OrderDate AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DELIVERYDATE AS CHAR),'NULL'))      > 1, CONCAT('DELIVERYDATE=',      GROUP_CONCAT(DISTINCT COALESCE(CAST(DELIVERYDATE AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DELIVERYDAYS AS CHAR),'NULL'))      > 1, CONCAT('DELIVERYDAYS=',      GROUP_CONCAT(DISTINCT COALESCE(CAST(DELIVERYDAYS AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(OrderTime AS CHAR),'NULL'))         > 1, CONCAT('OrderTime=',         GROUP_CONCAT(DISTINCT COALESCE(CAST(OrderTime AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(FinancialYear AS CHAR),'NULL'))     > 1, CONCAT('FinancialYear=',     GROUP_CONCAT(DISTINCT COALESCE(CAST(FinancialYear AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(Quarter AS CHAR),'NULL'))           > 1, CONCAT('Quarter=',           GROUP_CONCAT(DISTINCT COALESCE(CAST(Quarter AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(CustomerID AS CHAR),'NULL'))        > 1, CONCAT('CustomerID=',        GROUP_CONCAT(DISTINCT COALESCE(CAST(CustomerID AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(ProductID AS CHAR),'NULL'))         > 1, CONCAT('ProductID=',         GROUP_CONCAT(DISTINCT COALESCE(CAST(ProductID AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(Brand AS CHAR),'NULL'))             > 1, CONCAT('Brand=',             GROUP_CONCAT(DISTINCT COALESCE(CAST(Brand AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(MRP AS CHAR),'NULL'))               > 1, CONCAT('MRP=',               GROUP_CONCAT(DISTINCT COALESCE(CAST(MRP AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(Quantity AS CHAR),'NULL'))          > 1, CONCAT('Quantity=',          GROUP_CONCAT(DISTINCT COALESCE(CAST(Quantity AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(UnitPrice AS CHAR),'NULL'))         > 1, CONCAT('UnitPrice=',         GROUP_CONCAT(DISTINCT COALESCE(CAST(UnitPrice AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DiscountPercent AS CHAR),'NULL'))   > 1, CONCAT('DiscountPercent=',   GROUP_CONCAT(DISTINCT COALESCE(CAST(DiscountPercent AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(DiscountAmount AS CHAR),'NULL'))    > 1, CONCAT('DiscountAmount=',    GROUP_CONCAT(DISTINCT COALESCE(CAST(DiscountAmount AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(TaxableAmount AS CHAR),'NULL'))     > 1, CONCAT('TaxableAmount=',     GROUP_CONCAT(DISTINCT COALESCE(CAST(TaxableAmount AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(GSTPercent AS CHAR),'NULL'))        > 1, CONCAT('GSTPercent=',        GROUP_CONCAT(DISTINCT COALESCE(CAST(GSTPercent AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(GSTAmount AS CHAR),'NULL'))         > 1, CONCAT('GSTAmount=',         GROUP_CONCAT(DISTINCT COALESCE(CAST(GSTAmount AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(InvoiceAmount AS CHAR),'NULL'))     > 1, CONCAT('InvoiceAmount=',     GROUP_CONCAT(DISTINCT COALESCE(CAST(InvoiceAmount AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(PaymentMethod AS CHAR),'NULL'))     > 1, CONCAT('PaymentMethod=',     GROUP_CONCAT(DISTINCT COALESCE(CAST(PaymentMethod AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(EmiTenureMonths AS CHAR),'NULL'))   > 1, CONCAT('EmiTenureMonths=',   GROUP_CONCAT(DISTINCT COALESCE(CAST(EmiTenureMonths AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(EMIAmountPerMonth AS CHAR),'NULL')) > 1, CONCAT('EMIAmountPerMonth=', GROUP_CONCAT(DISTINCT COALESCE(CAST(EMIAmountPerMonth AS CHAR),'NULL'))), NULL),
IF(COUNT(DISTINCT COALESCE(CAST(OrderStatus AS CHAR),'NULL'))       > 1, CONCAT('OrderStatus=',       GROUP_CONCAT(DISTINCT COALESCE(CAST(OrderStatus AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(ChannelType AS CHAR),'NULL'))       > 1, CONCAT('ChannelType=',       GROUP_CONCAT(DISTINCT COALESCE(CAST(ChannelType AS CHAR),'NULL'))), NULL),
        IF(COUNT(DISTINCT COALESCE(CAST(StoreID AS CHAR),'NULL'))           > 1, CONCAT('StoreID=',           GROUP_CONCAT(DISTINCT COALESCE(CAST(StoreID AS CHAR),'NULL'))), NULL)
    ) AS differing_columns_with_values
FROM order_i
GROUP BY OrderID
HAVING COUNT(*) > 1
ORDER BY OrderID;

SELECT o.* FROM order_i o
JOIN (SELECT OrderID FROM order_i
    GROUP BY OrderID HAVING COUNT(*) > 1 AND MIN(Quantity) <> MAX(Quantity)) d ON d.OrderID = o.OrderID
ORDER BY o.OrderID;

SELECT o.OrderID,o.Quantity,o.OrderStatus,o.MRP,o.UnitPrice,
    o.DiscountPercent,o.DiscountAmount,o.TaxableAmount,o.GSTPercent,o.GSTAmount,o.InvoiceAmount,o.EMIAmountPerMonth
FROM order_i o
JOIN (SELECT OrderID FROM order_i GROUP BY OrderID HAVING COUNT(*) > 1
       AND MIN(Quantity) <> MAX(Quantity)) d ON d.OrderID = o.OrderID
ORDER BY o.OrderID, o.Quantity;

*/
-- Check if an Order has duplicate products (Composite Key Check)
SELECT OrderID, ProductID, COUNT(*) 
FROM order_full123
GROUP BY OrderID, ProductID 
HAVING COUNT(*) > 1;
-- =====================================================================================================================
-- ===================================================================================================================
-- *********************************************************************************************************************


-- data type change --
use freelancing;


ALTER TABLE CUSTOMER
MODIFY COLUMN CUSTOMERID VARCHAR(255),
MODIFY COLUMN CUSTOMERNAME VARCHAR(255),
MODIFY COLUMN GENDER VARCHAR(255),
MODIFY COLUMN AGE INT,
MODIFY COLUMN CUSTOMERSEGMENT VARCHAR(255),
MODIFY COLUMN City VARCHAR(255),
MODIFY COLUMN STATE VARCHAR(255);

ALTER TABLE PRODUCTDATA
MODIFY COLUMN PRODUCTID VARCHAR(255),
MODIFY COLUMN BRAND VARCHAR(255),
MODIFY COLUMN SERIES VARCHAR(255),
MODIFY COLUMN MODELNAME VARCHAR(255),
MODIFY COLUMN MODELCODE VARCHAR(255),
MODIFY COLUMN PROCESSORBRAND VARCHAR(255),
MODIFY COLUMN PROCESSORMODEL VARCHAR(255),
MODIFY COLUMN RAM_GB INT,
MODIFY COLUMN STORAGETYPE VARCHAR(255),
MODIFY COLUMN STORAGECAPACITY_GB VARCHAR(10),
MODIFY COLUMN GRAPHICSCARD VARCHAR(255),
MODIFY COLUMN SCREENSIZE_INCH DECIMAL(3,1),
MODIFY COLUMN OPERATINGSYSTEM VARCHAR(255),
MODIFY COLUMN COLOR VARCHAR(255),
MODIFY COLUMN LAUNCHYEAR YEAR,
MODIFY COLUMN PRODUCTCATEGORY VARCHAR(255),
MODIFY COLUMN MRP DECIMAL(10,2);


ALTER TABLE STOR
MODIFY COLUMN STOREID VARCHAR(255),
MODIFY COLUMN STORENAME VARCHAR(255),
MODIFY COLUMN STORECITY VARCHAR(255),
MODIFY COLUMN STORESTATE VARCHAR(255),
MODIFY COLUMN REGION VARCHAR(255);

desc ORDER_I;


ALTER TABLE ORDER_I
MODIFY COLUMN ORDERID VARCHAR(255),
MODIFY COLUMN ORDERDATE DATE,
MODIFY COLUMN ORDERTIME TIME,
MODIFY COLUMN DELIVERYDATE DATE,
MODIFY COLUMN FINANCIALYEAR CHAR(9),
MODIFY COLUMN QUARTER VARCHAR(255),
MODIFY COLUMN CustomerID VARCHAR(255),
MODIFY COLUMN ProductID VARCHAR(255),
MODIFY COLUMN Brand VARCHAR(255),
MODIFY COLUMN MRP DECIMAL(10,2),
MODIFY COLUMN QUANTITY INT,
MODIFY COLUMN UNITPRICE DECIMAL(10,2),
MODIFY COLUMN DISCOUNTPERCENT DECIMAL(10,2),
MODIFY COLUMN DISCOUNTAMOUNT DECIMAL(50,2),
MODIFY COLUMN TAXABLEAMOUNT DECIMAL(50,2),
MODIFY COLUMN GSTPERCENT DECIMAL(10,2),
MODIFY COLUMN GSTAMOUNT DECIMAL(10,2),
MODIFY COLUMN INVOICEAMOUNT DECIMAL(50,2),
MODIFY COLUMN PAYMENTMETHOD VARCHAR(255),
MODIFY COLUMN EMITENUREMONTHS VARCHAR(255),
MODIFY COLUMN EMIAMOUNTPERMONTH DECIMAL(10,2),
MODIFY COLUMN ORDERSTATUS VARCHAR(255),
MODIFY COLUMN DELIVERYDAYS INT,
MODIFY COLUMN CHANNELTYPE VARCHAR(255),
MODIFY COLUMN STOREID VARCHAR(255);

-- FOR ALL FILTERED TABLES COPY I ID THIS
/*
1. Add keys and indexes on the clean tables
If a PK fails, that table still has duplicate IDs. Find them with GROUP BY ... HAVING COUNT(*)>1.
*/
use freelancing;
ALTER TABLE CUSTOMER    ADD PRIMARY KEY (CUSTOMERID);
ALTER TABLE PRODUCTDATA ADD PRIMARY KEY (PRODUCTID);
ALTER TABLE STOR        ADD PRIMARY KEY (STOREID);
ALTER TABLE order123   ADD PRIMARY KEY (orderid);

desc order_i;
-- ORDER_I: no PK yet (ORDERID repeats), so index the join columns
CREATE INDEX idx_ord_id   ON ORDER123 (ORDERID);
CREATE INDEX idx_ord_cust ON ORDER123 (CUSTOMERID);
CREATE INDEX idx_ord_prod ON ORDER123 (PRODUCTID);
CREATE INDEX idx_ord_store ON ORDER123 (STOREID);
CREATE INDEX idx_ord_date ON ORDER123 (ORDERDATE);

/*
CREATE OR REPLACE VIEW order_full AS
SELECT 
    o.OrderID,o.OrderDate,o.OrderTime,o.FinancialYear,o.Quarter,o.CustomerID,c.CustomerName,
    c.Gender,c.Age,c.CustomerSegment,o.ProductID,p.Brand,p.Series,p.ModelName,p.ModelCode,p.ProcessorBrand,p.ProcessorModel,
    p.RAM_GB,p.StorageType,p.StorageCapacity_GB,p.GraphicsCard,
    p.ScreenSize_inch,p.operatingsystem       AS OperatingSystem,p.Color,p.LaunchYear,p.ProductCategory,
    p.MRP,o.Quantity,o.UnitPrice,o.DiscountPercent,o.DiscountAmount,o.TaxableAmount,o.GSTPercent,o.GSTAmount,
    o.InvoiceAmount,o.PaymentMethod,o.EmiTenureMonths       AS EMITenureMonths,o.EMIAmountPerMonth,o.OrderStatus,
    o.DELIVERYDATE   AS DeliveryDate,
    o.DELIVERYDAYS   AS DeliveryDays,o.ChannelType,o.StoreID,s.StoreName,  s.StoreCity,s.StoreState,s.Region
FROM order_i o
LEFT JOIN customer    c ON o.CustomerID = c.CustomerID
LEFT JOIN productdata p ON o.ProductID  = p.ProductID
LEFT JOIN stor        s ON o.StoreID    = s.StoreID;

*/
 DROP VIEW BASE_view ;
-- =====================================================================
-- base_view: one row per order, IDs only (no descriptive text)
--   Order facts + order-level info from Order_i
--   Corrected money columns + EMI details from PRICE
-- =====================================================================
DROP VIEW IF EXISTS reporting_view;
DROP VIEW IF EXISTS base_view;

CREATE OR REPLACE VIEW base_view AS
SELECT
    o.OrderID,o.OrderDate,o.OrderTime,
    o.FinancialYear,o.Quarter,o.CustomerID,o.ProductID,o.StoreID,pr.MRP,PR.Quantity,pr.UnitPrice,
    pr.DiscountPercent,pr.DiscountAmount,pr.TaxableAmount,pr.GSTPercent,pr.GSTAmount,pr.InvoiceAmount,
    o.PaymentMethod,o.EMITenureMonths,pr.EMIAmountPerMonth,o.OrderStatus,          -- from Order_i (the corrected one)
o.DeliveryDate,o.DeliveryDays,o.ChannelType
FROM Order_i o
JOIN Price pr ON pr.OrderID = o.OrderID;   -- 1 row per order in PRICE


-- =====================================================================
-- reporting_view: base_view + descriptive columns from the 3 dimensions
-- =====================================================================
CREATE or replace VIEW reporting_view AS
SELECT
    b.OrderID,b.OrderDate,b.OrderTime,b.FinancialYear,b.Quarter,
    -- customer    --  c.City      AS CustomerCity, c.State     AS CustomerState,
    b.CustomerID,c.CustomerName,c.Gender,c.Age,c.CustomerSegment,
    -- product
    b.ProductID,
    p.Brand,p.Series, p.ModelName,p.ModelCode,p.ProcessorBrand,p.ProcessorModel,p.RAM_GB,p.StorageType,
    p.StorageCapacity_GB,p.GraphicsCard,p.ScreenSize_inch,p.OperatingSystem,p.Color,p.LaunchYear,p.ProductCategory,
    -- money (already corrected in base_view)
    b.MRP,b.Quantity,b.UnitPrice,b.DiscountPercent,b.DiscountAmount,
    b.TaxableAmount,b.GSTPercent,b.GSTAmount,b.InvoiceAmount,b.PaymentMethod,b.EMITenureMonths,b.EMIAmountPerMonth,
    -- order / delivery
    b.OrderStatus,b.DeliveryDate,b.DeliveryDays,b.ChannelType,
    -- store
    b.StoreID,s.StoreName,s.StoreCity,s.StoreState,s.Region
FROM base_view b
LEFT JOIN Customer    c ON c.CustomerID = b.CustomerID
LEFT JOIN Productdata p ON p.ProductID  = b.ProductID
LEFT JOIN Stor        s ON s.StoreID    = b.StoreID;
-- =====================================================================
-- Sanity checks (run once after creating)
-- =====================================================================
-- 1) Every order should appear exactly once
SELECT (SELECT COUNT(*) FROM Order_i)        AS orders,
       (SELECT COUNT(*) FROM base_view)      AS base_rows,
       (SELECT COUNT(*) FROM reporting_view) AS reporting_rows;

-- 2) PRICE must have one row per OrderID (should return no rows)
SELECT OrderID, COUNT(*) FROM Price GROUP BY OrderID HAVING COUNT(*) > 1;

-- 3) Dimension IDs must be unique (each should return no rows)
SELECT CustomerID, COUNT(*) FROM Customer    GROUP BY CustomerID HAVING COUNT(*) > 1;
SELECT ProductID,  COUNT(*) FROM Productdata GROUP BY ProductID  HAVING COUNT(*) > 1;
SELECT StoreID,    COUNT(*) FROM Stor        GROUP BY StoreID    HAVING COUNT(*) > 1;

-- 4) Orders with no matching dimension row (should be 0)
SELECT COUNT(*) AS missing_dim
FROM reporting_view
WHERE CustomerName IS NULL OR Brand IS NULL OR StoreName IS NULL;