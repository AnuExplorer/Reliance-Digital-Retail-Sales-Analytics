-- ================================================================================================
-- RELIANCE LAPTOP SALES — DATA CLEANING & TRANSFORMATION PIPELINE (ANNOTATED)
-- ================================================================================================
-- This script takes a raw CSV export of laptop sales transactions, loads it into MySQL, and then
-- progressively cleans, standardizes, and recalculates the data so it is analysis-ready.
-- Comments below explain WHY each block exists (Purpose) and WHAT you should expect to see
-- (Example Result) when you run it, so future-you (or a teammate) can follow the logic quickly.
-- ================================================================================================

use reliance;
drop table reliance;
select * from laptop_sales;
select * from main;

-- ------------------------------------------------------------------------------------------------
-- SECTION 1: CREATE RAW STAGING TABLE
-- PURPOSE : Define a landing table with every column as VARCHAR(255). Using text for everything
--           at import time avoids load failures caused by dirty data (blanks, symbols, wrong
--           formats) that would break a strict numeric/date type on first load.
-- EXAMPLE RESULT: An empty table `laptop_sales` with 55 text columns, ready to receive the CSV.
-- ------------------------------------------------------------------------------------------------
CREATE TABLE MAIN(
    TransactionID VARCHAR(255),
    OrderID VARCHAR(255),
    OrderDate VARCHAR(255),
    OrderTime VARCHAR(255),
    FinancialYear VARCHAR(255),
    Quarter VARCHAR(255),
    CustomerID VARCHAR(255),
    CustomerName VARCHAR(255),
    Gender VARCHAR(255),
    Age VARCHAR(255),
    CustomerPhone VARCHAR(255),
    CustomerEmail VARCHAR(255),
    CustomerAddress VARCHAR(255),
    City VARCHAR(255),
    State VARCHAR(255),
    PinCode VARCHAR(255),
    CustomerSegment VARCHAR(255),
    ProductID VARCHAR(255),
    Brand VARCHAR(255),
    Series VARCHAR(255),
    ModelName VARCHAR(255),
    ModelCode VARCHAR(255),
    ProcessorBrand VARCHAR(255),
    ProcessorModel VARCHAR(255),
    RAM_GB VARCHAR(255),
    StorageType VARCHAR(255),
    StorageCapacity_GB VARCHAR(255),
    GraphicsCard VARCHAR(255),
    ScreenSize_inch VARCHAR(255),
    OperatingSystem VARCHAR(255),
    Color VARCHAR(255),
    LaunchYear VARCHAR(255),
    ProductCategory VARCHAR(255),
    MRP VARCHAR(255),
    Quantity VARCHAR(255),
    UnitPrice VARCHAR(255),
    DiscountPercent VARCHAR(255),
    DiscountAmount VARCHAR(255),
    TaxableAmount VARCHAR(255),
    GSTPercent VARCHAR(255),
    GSTAmount VARCHAR(255),
    InvoiceAmount VARCHAR(255),
    PaymentMethod VARCHAR(255),
    EMITenureMonths VARCHAR(255),
    EMIAmountPerMonth VARCHAR(255),
    OrderStatus VARCHAR(255),
    DeliveryDate VARCHAR(255),
    DeliveryDays VARCHAR(255),
    ChannelType VARCHAR(255),
    StoreID VARCHAR(255),
    StoreName VARCHAR(255),
    StoreCity VARCHAR(255),
    StoreState VARCHAR(255),
    Region VARCHAR(255),
    DealerName VARCHAR(255),
    SalesRepID VARCHAR(255),
    SalesRepName VARCHAR(255)
);

-- ------------------------------------------------------------------------------------------------
-- SECTION 2: IMPORT RAW CSV
-- PURPOSE : Enable local file loading (disabled by default in MySQL for security) and bulk-load
--           the source CSV into the staging table created above.
-- EXAMPLE RESULT: SHOW VARIABLES LIKE 'LOCAL_INFILE' returns ON. After LOAD DATA, `laptop_sales`
--           is populated with N rows (one per CSV data row, header row skipped by IGNORE 1 ROWS).
-- ------------------------------------------------------------------------------------------------
SET GLOBAL LOCAL_INFILE= 1;
SHOW VARIABLES LIKE 'LOCAL_INFILE';

LOAD DATA LOCAL INFILE "C:/Users/anubh/Downloads/REAL FREE RELIDIGI.csv"
INTO TABLE MAIN
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- ------------------------------------------------------------------------------------------------
-- SECTION 3: CREATE WORKING COPY
-- PURPOSE : Never clean the raw import table directly — work on a copy (`reliance`) so the
--           original load can always be re-checked or re-created if a cleaning step goes wrong.
-- EXAMPLE RESULT: `reliance` is an exact duplicate of `laptop_sales`, same row/column count.
-- ------------------------------------------------------------------------------------------------
-- CREATE NEW TABLE AFTER IMPORT TO KEEP MAIN DATA SAFE AFTER IMPORT TABLE FROM
create table reliance select * from MAIN;
-- ----------------------------------------------------------------------------------------
-- DATA TYPE CHANGES ON NEW COLUMNS
ALTER TABLE COPY1
MODIFY COLUMN ORDERID VARCHAR(255),
MODIFY COLUMN FINANCIALYEAR VARCHAR(255),
MODIFY COLUMN QUARTER VARCHAR(255),
MODIFY COLUMN CUSTOMERID VARCHAR(255),
MODIFY COLUMN CUSTOMERNAME VARCHAR(255),
MODIFY COLUMN GENDER VARCHAR(255),
MODIFY COLUMN AGE INT,
MODIFY COLUMN CUSTOMERSEGMENT VARCHAR(255),
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
MODIFY COLUMN MRP DECIMAL(10,2),
MODIFY COLUMN QUANTITY INT,
MODIFY COLUMN UNITPRICE DECIMAL(10,2),
MODIFY COLUMN DISCOUNTPERCENT DECIMAL(10,2),
MODIFY COLUMN DISCOUNTAMOUNT DECIMAL(10,2),
MODIFY COLUMN TAXABLEAMOUNT DECIMAL(10,2),
MODIFY COLUMN GSTPERCENT DECIMAL(10,2),
MODIFY COLUMN GSTAMOUNT DECIMAL(10,2),
MODIFY COLUMN INVOICEAMOUNT DECIMAL(10,2),
MODIFY COLUMN PAYMENTMETHOD VARCHAR(255),
MODIFY COLUMN EMITENUREMONTHS INT,
MODIFY COLUMN EMIAMOUNTPERMONTH DECIMAL(10,2),
MODIFY COLUMN ORDERSTATUS VARCHAR(255),
MODIFY COLUMN DELIVERYDAYS INT,
MODIFY COLUMN CHANNELTYPE VARCHAR(255),
MODIFY COLUMN STORENAME VARCHAR(255),
MODIFY COLUMN STORECITY VARCHAR(255),
MODIFY COLUMN STORESTATE VARCHAR(255),
MODIFY COLUMN REGION VARCHAR(255);
describe copy1;
-- ========================================
-- THIS IS REMAININNG TO CHANGE ITS DATATYPE
ALTER TABLE COPY1
MODIFY COLUMN ORDERDATE DATE,
MODIFY COLUMN ORDERTIME TIME;
-- ==============================================
DESCRIBE COPY;

-- ------------------------------------------------------------------------------------------------
-- SECTION 4: ADD A SURROGATE PRIMARY KEY
-- PURPOSE : The source data has no reliable single-row identifier (TransactionID/OrderID can
--           repeat across split orders). IDX_NO gives every physical row a unique, sequential
--           integer to act as a primary key for joins, ordering, and de-duplication checks.
-- EXAMPLE RESULT: IDX_NO column added as the first column, values 111, 112, 113 ... running
--           consecutively (starting at @num+1 = 111 here) with zero NULLs.
-- ------------------------------------------------------------------------------------------------
ALTER TABLE reliance
DROP COLUMN IDX_NO;

ALTER TABLE reliance ADD COLUMN SRC_ID INT;

ALTER TABLE reliance MODIFY COLUMN SRC_ID INT AUTO_INCREMENT PRIMARY KEY FIRST;

SET @SRC_ID = 0;

UPDATE reliance
SET
    SRC_ID = (@SRC_ID:=@SRC_ID + 1);

-- Sanity checks: confirm every row got a value and the count matches the table's row count.
SELECT *
FROM reliance
WHERE SRC_ID IS NULL;                      -- Expected result: 0 rows returned
SELECT COUNT(*) AS TotalRows
FROM reliance;                             -- Expected result: total row count, e.g. 50,000
SELECT COUNT(SRC_ID) AS NonNullCount
FROM reliance;                             -- Expected result: same number as TotalRows above

SELECT *
FROM MAIN;
-- 29-008-2026

/*
PURPOSE (Hinglish note kept from original, translated below):
We are first deleting the columns that are not important for our analysis, and we are removing
these columns only from our working/copy table. In the original raw dataset, all these columns
remain untouched. The column names we are deleting are listed below.
COLUMN NAME:
1-12, the remaining 45 columns stay as-is.
These are the columns that have been deleted.
*/

-- ------------------------------------------------------------------------------------------------
-- SECTION 5: DROP UNNECESSARY / SENSITIVE COLUMNS
-- PURPOSE : Remove PII (phone, email, address), redundant location fields already captured
--           elsewhere (City/State duplicate Store_City/Store_State), and identifiers not needed
--           for analysis (TransactionID, StoreID, SalesRep/Dealer names) — both to reduce noise
--           and to avoid carrying personal data into reporting layers.
-- EXAMPLE RESULT: `reliance` now has 55 - 12 = 43 columns (before IDX_NO/RESULT are added later).
-- ------------------------------------------------------------------------------------------------
ALTER TABLE reliance
DROP COLUMN CUSTOMERPHONE,
DROP COLUMN CUSTOMEREMAIL,
DROP COLUMN DEALERNAME,
DROP COLUMN SALESREPID,
DROP COLUMN PINCODE,
DROP COLUMN TRANSACTIONID,
DROP COLUMN DELIVERYDATE,
DROP COLUMN SALESREPNAME,
DROP COLUMN CUSTOMERADDRESS;
SELECT * FROM RELIANCE;
ALTER TABLE RELIANCE DROP COLUMN IDX_NO;
-- Verification: confirm the dropped columns no longer exist in the schema.
-- EXAMPLE RESULT: 0 rows returned (none of the 12 names should show up anymore).
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'reliance'
  AND COLUMN_NAME IN (
    'CUSTOMERPHONE','CUSTOMEREMAIL','DEALERNAME','SALESREPID',
    'PINCODE','TRANSACTIONID','CITY','STATE','DELIVERYDATE',
    'STOREID','SALESREPNAME','CUSTOMERADDRESS'
  );

-- Note: don't run drop/rename yet — do it last; keep a note of the line numbers for both the
-- drop and the renaming so they can be re-run together at the end of the pipeline.
-- ***********************************************************************************
-- ------------------------------------------------------------------------------------------------
-- SECTION 6: RENAME COLUMNS TO snake_case
-- PURPOSE : Standardize naming convention (CamelCase -> Snake_Case with underscores) for
--           readability and consistency with BI-tool/reporting naming conventions.
-- NOTE    : This block targets a table called `COPY`, not `reliance` — make sure you run it
--           against the correct table name (rename to `reliance` if `COPY` was only a working
--           alias name used earlier in development).
-- EXAMPLE RESULT: `OrderID` becomes `Order_ID`, `CustomerName` becomes `Customer_Name`, etc.
--           Columns that were already a single word (Gender, Age, Brand, Color...) are unchanged.
-- ------------------------------------------------------------------------------------------------
ALTER TABLE COPY
    RENAME COLUMN OrderID TO Order_ID,
    RENAME COLUMN OrderDate TO Order_Date,
    RENAME COLUMN OrderTime TO Order_Time,
    RENAME COLUMN FinancialYear TO Financial_Year,
    RENAME COLUMN Quarter TO Quarter,
    RENAME COLUMN CustomerID TO Customer_ID,
    RENAME COLUMN CustomerName TO Customer_Name,
    RENAME COLUMN Gender TO Gender,
    RENAME COLUMN Age TO Age,
    -- RENAME COLUMN CustomerAddress TO Customer_Address,
    RENAME COLUMN CustomerSegment TO Customer_Segment,
    RENAME COLUMN ProductID TO Product_ID,
    RENAME COLUMN Brand TO Brand,
    RENAME COLUMN Series TO Series,
    RENAME COLUMN ModelName TO Model_Name,
    RENAME COLUMN ModelCode TO Model_Code,
    RENAME COLUMN ProcessorBrand TO Processor_Brand,
    RENAME COLUMN ProcessorModel TO Processor_Model,
    RENAME COLUMN RAM_GB TO RAM_GB,
    RENAME COLUMN StorageType TO Storage_Type,
    RENAME COLUMN StorageCapacity_GB TO Storage_Capacity_GB,
    RENAME COLUMN GraphicsCard TO Graphics_Card,
    RENAME COLUMN ScreenSize_inch TO Screen_Size_inch,
    RENAME COLUMN OperatingSystem TO Operating_System,
    RENAME COLUMN Color TO Color,
    RENAME COLUMN LaunchYear TO Launch_Year,
    RENAME COLUMN ProductCategory TO Product_Category,
    RENAME COLUMN MRP TO MRP,
    RENAME COLUMN Quantity TO Quantity,
    RENAME COLUMN UnitPrice TO Unit_Price,
    RENAME COLUMN DiscountPercent TO Discount_Percent,
    RENAME COLUMN DiscountAmount TO Discount_Amount,
    RENAME COLUMN TaxableAmount TO Taxable_Amount,
    RENAME COLUMN GSTPercent TO GST_Percent,
    RENAME COLUMN GSTAmount TO GST_Amount,
    RENAME COLUMN InvoiceAmount TO Invoice_Amount,
    RENAME COLUMN PaymentMethod TO Payment_Method,
    RENAME COLUMN EMITenureMonths TO EMI_Tenure_Months,
    RENAME COLUMN EMIAmountPerMonth TO EMI_Amount_Per_Month,
    RENAME COLUMN OrderStatus TO Order_Status,
    RENAME COLUMN DeliveryDays TO Delivery_Days,
    RENAME COLUMN ChannelType TO Channel_Type,
    RENAME COLUMN StoreName TO Store_Name,
    RENAME COLUMN StoreCity TO Store_City,
    RENAME COLUMN StoreState TO Store_State,
    RENAME COLUMN Region TO Region;

-- ------------------------------------------------------------------------------------------------
-- SECTION 7: COLUMN COUNT CHECK
-- PURPOSE : Quick sanity check after dropping/renaming — confirms the table has the expected
--           number of remaining columns before moving on to value-level cleaning.
-- EXAMPLE RESULT: 'total column' = 44 (55 original + IDX_NO - 12 dropped).
-- ------------------------------------------------------------------------------------------------
select count(*) as 'total column'
from information_schema.columns
where table_name ='reliance' and table_schema ='reliance';

-- ------------------------------------------------------------------------------------------------
-- SECTION 8: CLEAN CUSTOMER NAME (remove stray symbols/digits)
-- PURPOSE : Customer names should contain only letters and spaces. This finds and strips out
--           any junk characters (digits, punctuation, symbols) that leaked in from the source
--           system, and collapses repeated spaces into one.
-- EXAMPLE RESULT: 'Ravi_Kumar123' -> 'Ravi Kumar' ; 'Ananya   Singh!!' -> 'Ananya Singh'
-- ------------------------------------------------------------------------------------------------
SELECT CUSTOMERNAME AS 'CUSTOMER NAME' FROM reliance WHERE CUSTOMERNAME REGEXP '[^A-Za-z0-9 ]';
SELECT COUNT(CUSTOMERNAME) AS 'CUSTOMER NAME' FROM reliance WHERE CUSTOMERNAME REGEXP '[^A-Za-z0-9 ]';
-- SOLUTION --
UPDATE reliance
SET CUSTOMERNAME = TRIM(REGEXP_REPLACE(REGEXP_REPLACE(CUSTOMERNAME,'[^A-Za-z ]',' '),' +',' '))
WHERE CUSTOMERNAME IS NOT NULL;
-- CHECK YOUR DATA
SELECT * FROM reliance;

/* Summary of cleaning applied below:
   Cleaned Numbers & Amounts: Removed all symbols, letters, and spaces from numeric and currency
   columns, converting empty results to NULL. Standardised IDs: Converted OrderID, CustomerID,
   ProductID, and ModelCode to uppercase and removed extra spaces. Text Formatting: Cleaned up
   spacing and padding errors across all descriptive columns (Dates, Customer details, Product
   specs, and Locations), turning blank entries into NULL.
*/

-- ------------------------------------------------------------------------------------------------
-- SECTION 9: CLEAN NUMERIC / CURRENCY COLUMNS (strip non-numeric characters)
-- PURPOSE : Prices and amounts arrived as text and may contain currency symbols, letters, or
--           stray characters (e.g. "₹45,000", "45000rs"). Strip everything except digits and
--           the decimal point, and turn any resulting empty string into NULL (instead of '').
-- EXAMPLE RESULT: '₹45,000.00' -> '45000.00' ; 'N/A' -> NULL ; '38999/-' -> '38999'
-- ------------------------------------------------------------------------------------------------
UPDATE reliance SET
    MRP = NULLIF(TRIM(REGEXP_REPLACE(MRP, '[^0-9.]', '')), ''),
    UnitPrice = NULLIF(TRIM(REGEXP_REPLACE(UnitPrice, '[^0-9.]', '')), ''),
	DiscountPERCENT = NULLIF(TRIM(REGEXP_REPLACE(DiscountPERCENT, '[^0-9.]', '')), ''),
    DiscountAmount = NULLIF(TRIM(REGEXP_REPLACE(DiscountAmount, '[^0-9.]', '')), ''),
    TaxableAmount = NULLIF(TRIM(REGEXP_REPLACE(TaxableAmount, '[^0-9.]', '')), ''),
    GSTAmount = NULLIF(TRIM(REGEXP_REPLACE(GSTAmount, '[^0-9.]', '')), ''),
    InvoiceAmount = NULLIF(TRIM(REGEXP_REPLACE(InvoiceAmount, '[^0-9.]', '')), ''),
    EMIAmountPerMonth = NULLIF(TRIM(REGEXP_REPLACE(EMIAmountPerMonth, '[^0-9.]', '')), '');

-- PURPOSE : Same cleaning as above, applied to whole-number/integer-style columns (no decimals
--           expected), plus percentage columns that may still carry decimals.
-- EXAMPLE RESULT: '16 GB' -> '16' ; '15.6 inch' -> '15.6' ; '' -> NULL
UPDATE reliance SET
    Age = NULLIF(TRIM(REGEXP_REPLACE(Age, '[^0-9]', '')),''),
    Quantity = NULLIF(TRIM(REGEXP_REPLACE(Quantity, '[^0-9]', '')),''),
    RAM_GB = NULLIF(TRIM(REGEXP_REPLACE(RAM_GB, '[^0-9]', '')),''),
    StorageCapacity_GB = NULLIF(TRIM(REGEXP_REPLACE(StorageCapacity_GB, '[^0-9]', '')),''),
    EMITenureMonths = NULLIF(TRIM(REGEXP_REPLACE(EMITenureMonths, '[^0-9]', '')),''),
    DeliveryDays = NULLIF(TRIM(REGEXP_REPLACE(DeliveryDays, '[^0-9]', '')),''),
    DiscountPercent = NULLIF(TRIM(REGEXP_REPLACE(DiscountPercent, '[^0-9.]', '')),''),
    GSTPercent = NULLIF(TRIM(REGEXP_REPLACE(GSTPercent, '[^0-9.]', '')),''),
    ScreenSize_inch = NULLIF(TRIM(REGEXP_REPLACE(ScreenSize_inch, '[^0-9.]', '')),'');
DESCRIBE reliance;

-- ------------------------------------------------------------------------------------------------
-- SECTION 10: STANDARDIZE ID COLUMNS
-- PURPOSE : IDs should be consistent case and free of stray whitespace so joins/lookups
--           ('RD-ORD-504270' vs 'rd-ord-504270 ') don't silently fail to match.
-- EXAMPLE RESULT: 'rd-ord-504270 ' -> 'RD-ORD-504270' ; '  cust-0091' -> 'CUST-0091'
-- ------------------------------------------------------------------------------------------------
UPDATE reliance
SET
    OrderID = NULLIF(UPPER(REGEXP_REPLACE(TRIM(OrderID), ' +', ' ')), ''),
    CustomerID = NULLIF(UPPER(REGEXP_REPLACE(TRIM(CustomerID), ' +', ' ')), ''),
    ProductID = NULLIF(UPPER(REGEXP_REPLACE(TRIM(ProductID), ' +', ' ')), ''),
    ModelCode = NULLIF(UPPER(REGEXP_REPLACE(TRIM(ModelCode), ' +', ' ')), '');

-- ------------------------------------------------------------------------------------------------
-- SECTION 11: TRIM / NORMALIZE SPACING ON ALL REMAINING TEXT COLUMNS
-- PURPOSE : Collapse double spaces and leading/trailing whitespace across every descriptive
--           text column (dates, demographics, product specs, transaction and location fields)
--           and convert blank strings to true NULLs so aggregate functions treat them correctly.
-- EXAMPLE RESULT: 'Delhi   ' -> 'Delhi' ; '  Female' -> 'Female' ; '' -> NULL
-- ------------------------------------------------------------------------------------------------
create table reliance select * from basicfilter;
UPDATE reliance SET
-- 1. Date, Time & Year Columns (Cleans spacing issues)
    OrderDate = NULLIF(TRIM(REGEXP_REPLACE(OrderDate, ' +', ' ')), ''),
    OrderTime = NULLIF(TRIM(REGEXP_REPLACE(OrderTime, ' +', ' ')), ''),
    FinancialYear = NULLIF(UPPER(TRIM(REGEXP_REPLACE(FinancialYear, ' +', ' '))), ''),
    Quarter = NULLIF(UPPER(TRIM(REGEXP_REPLACE(Quarter, ' +', ' '))), ''),
    LaunchYear = NULLIF(TRIM(REGEXP_REPLACE(LaunchYear, ' +', ' ')), ''),
-- 2. Customer & Demographic Details
    CustomerName = NULLIF(TRIM(REGEXP_REPLACE(CustomerName, ' +', ' ')), ''),
    Gender = NULLIF(TRIM(REGEXP_REPLACE(Gender, ' +', ' ')), ''),
    CustomerSegment = NULLIF(TRIM(REGEXP_REPLACE(CustomerSegment, ' +', ' ')), ''),
-- 3. Product & Technical Text Categories
    Brand = NULLIF(TRIM(REGEXP_REPLACE(Brand, ' +', ' ')), ''),
    Series = NULLIF(TRIM(REGEXP_REPLACE(Series, ' +', ' ')), ''),
    ModelName = NULLIF(TRIM(REGEXP_REPLACE(ModelName, ' +', ' ')), ''),
    ProcessorBrand = NULLIF(TRIM(REGEXP_REPLACE(ProcessorBrand, ' +', ' ')), ''),
    ProcessorModel = NULLIF(TRIM(REGEXP_REPLACE(ProcessorModel, ' +', ' ')), ''),
    StorageType = NULLIF(TRIM(REGEXP_REPLACE(StorageType, ' +', ' ')), ''),
    GraphicsCard = NULLIF(TRIM(REGEXP_REPLACE(GraphicsCard, ' +', ' ')), ''),
    OperatingSystem = NULLIF(TRIM(REGEXP_REPLACE(OperatingSystem, ' +', ' ')), ''),
    Color = NULLIF(TRIM(REGEXP_REPLACE(Color, ' +', ' ')), ''),
    ProductCategory = NULLIF(TRIM(REGEXP_REPLACE(ProductCategory, ' +', ' ')), ''),
-- 4. Transactional & Order Status Details
    PaymentMethod = NULLIF(TRIM(REGEXP_REPLACE(PaymentMethod, ' +', ' ')), ''),
    OrderStatus = NULLIF(TRIM(REGEXP_REPLACE(OrderStatus, ' +', ' ')), ''),
-- 5. Store & Location Hierarchies
    ChannelType = NULLIF(TRIM(REGEXP_REPLACE(ChannelType, ' +', ' ')), ''),
    StoreName = NULLIF(TRIM(REGEXP_REPLACE(StoreName, ' +', ' ')), ''),
    StoreCity = NULLIF(TRIM(REGEXP_REPLACE(StoreCity, ' +', ' ')), ''),
    StoreState = NULLIF(TRIM(REGEXP_REPLACE(StoreState, ' +', ' ')), ''),
    Region = NULLIF(TRIM(REGEXP_REPLACE(Region, ' +', ' ')), ''),
-- 6.  Column FOR DROP
    CustomerAddress = NULLIF(TRIM(REGEXP_REPLACE(CustomerAddress, ' +', ' ')), ''),
    CustomerPhone = NULLIF(TRIM(REGEXP_REPLACE(CustomerPhone, ' +', ' ')), ''),
    CustomerEmail = NULLIF(TRIM(REGEXP_REPLACE(CustomerEmail, ' +', ' ')), ''),
    DealerName = NULLIF(TRIM(REGEXP_REPLACE(DealerName, ' +', ' ')), ''),
    SalesRepID = NULLIF(TRIM(REGEXP_REPLACE(SalesRepID, ' +', ' ')), ''),
    Pincode = NULLIF(TRIM(REGEXP_REPLACE(Pincode, ' +', ' ')), ''),
    TransactionID = NULLIF(TRIM(REGEXP_REPLACE(TransactionID, ' +', ' ')), ''),
    City = NULLIF(TRIM(REGEXP_REPLACE(City, ' +', ' ')), ''),
    State = NULLIF(TRIM(REGEXP_REPLACE(State, ' +', ' ')), ''),
    DeliveryDate = NULLIF(TRIM(REGEXP_REPLACE(DeliveryDate, ' +', ' ')), ''),
    StoreID = NULLIF(TRIM(REGEXP_REPLACE(StoreID, ' +', ' ')), ''),
    SalesRepName = NULLIF(TRIM(REGEXP_REPLACE(SalesRepName, ' +', ' ')), '');
    
-- ------------------------------------------------------------------------------------------------
-- SECTION 12: DETECT & FIX ABNORMAL PRICE VALUES
-- PURPOSE : After stripping non-numeric characters, a few price fields can still fail to match a
--           clean "digits(.digits)" pattern (e.g. a value that was JUST a decimal point with
--           digits, like '.4599', likely caused by an OCR/parsing glitch that dropped a leading
--           digit or a stray currency symbol before the dot). This audits how many rows are
--           still abnormal, and fixes the specific ".NNNN" pattern by removing the stray dot.
-- EXAMPLE RESULT: Audit query might show MRP_abnormal = 12, UnitPrice_abnormal = 4.
--           Fix step: '.4599' -> '4599'
-- ------------------------------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN MRP NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS MRP_abnormal,
    SUM(CASE WHEN UnitPrice NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS UnitPrice_abnormal,
    SUM(CASE WHEN DiscountAmount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS DiscountAmount_abnormal,
    SUM(CASE WHEN TaxableAmount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS TaxableAmount_abnormal,
    SUM(CASE WHEN GSTAmount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS GSTAmount_abnormal,
    SUM(CASE WHEN InvoiceAmount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS InvoiceAmount_abnormal,
    SUM(CASE WHEN EMIAmountPerMonth NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 1 ELSE 0 END) AS EMIAmountPerMonth_abnormal
FROM reliance;

SELECT DISTINCT MRP AS abnormal_value, 'MRP' AS column_name
FROM reliance
WHERE MRP NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
UNION ALL
SELECT DISTINCT UnitPrice, 'UnitPrice'
FROM reliance
WHERE UnitPrice NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- Frequency breakdowns, useful to eyeball what the abnormal patterns actually look like.
SELECT MRP AS abnormal_value, COUNT(*) AS occurrences
FROM reliance
WHERE MRP NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
GROUP BY MRP
ORDER BY occurrences DESC;

SELECT UnitPrice AS abnormal_value, COUNT(*) AS occurrences
FROM reliance
WHERE UnitPrice NOT REGEXP '^[0-9]+(\\.[0-9]+)?$'
GROUP BY UnitPrice
ORDER BY occurrences DESC;

-- Preview the fix before applying it.
SELECT
    MRP AS abnormal_value,
    REPLACE(MRP, '.', '') AS fixed_value,
    'MRP' AS column_name
FROM reliance
WHERE MRP REGEXP '^\\.[0-9]+$'
UNION ALL
SELECT
    UnitPrice AS abnormal_value,
    REPLACE(UnitPrice, '.', '') AS fixed_value,
    'UnitPrice' AS column_name
FROM reliance
WHERE UnitPrice REGEXP '^\\.[0-9]+$';

-- Apply the fix.
UPDATE reliance
SET MRP = REPLACE(MRP, '.', '')
WHERE MRP REGEXP '^\\.[0-9]+$';


UPDATE reliance
SET UnitPrice = REPLACE(UnitPrice, '.', '')
WHERE UnitPrice REGEXP '^\\.[0-9]+$';

-- ------------------------------------------------------------------------------------------------
-- SECTION 13: STANDARDIZE GENDER VALUES
-- PURPOSE : Source data mixes abbreviations ('M'/'F') with full words ('MALE'/'FEMALE'). Collapse
--           both spellings into one consistent value per gender for clean grouping in reports.
-- EXAMPLE RESULT: 'M' -> 'MALE' ; 'f' would need upper-casing first, but 'F' -> 'FEMALE'
-- ------------------------------------------------------------------------------------------------
SELECT
    Gender AS OG,
    CASE
        WHEN Gender IN ('MALE', 'M') THEN 'MALE'
        WHEN Gender IN ('FEMALE', 'F') THEN 'FEMALE'
        ELSE Gender
    END AS updated_gender
FROM reliance;

UPDATE reliance
SET Gender = CASE
    WHEN Gender IN ('MALE', 'M') THEN 'MALE'
    WHEN Gender IN ('FEMALE', 'F') THEN 'FEMALE'
    ELSE Gender
END;

-- ------------------------------------------------------------------------------------------------
-- SECTION 14: STANDARDIZE CUSTOMER SEGMENT VALUES
-- PURPOSE : Segment labels came in with inconsistent spelling/synonyms ('NEW CUSTOMRE' typo,
--           'RETURNING' vs 'REPEAT', 'RELIANCE ONE MEMBER' vs 'PREMIUM'). Map every variant to
--           one canonical label per segment.
-- EXAMPLE RESULT: 'NEW CUSTOMRE' -> 'NEW CUSTOMER' ; 'RETURNING' -> 'REPEAT' ;
--           'RELIANCE ONE MEMBER' -> 'PREMIUM'
-- ------------------------------------------------------------------------------------------------
SELECT
    CUSTOMERSEGMENT,
    CASE
        WHEN CUSTOMERSEGMENT IN ('NEW', 'NEW CUSTOMRE') THEN 'NEW CUSTOMER'
        WHEN CUSTOMERSEGMENT IN ('REPEAT', 'RETURNING') THEN 'REPEAT'
        WHEN CUSTOMERSEGMENT IN ('PREMIUM', 'RELIANCE ONE MEMBER') THEN 'PREMIUM'
        ELSE CUSTOMERSEGMENT
    END
FROM reliance;

UPDATE reliance
SET CUSTOMERSEGMENT = CASE
        WHEN CUSTOMERSEGMENT IN ('NEW', 'NEW CUSTOMRE') THEN 'NEW CUSTOMER'
        WHEN CUSTOMERSEGMENT IN ('REPEAT', 'RETURNING') THEN 'REPEAT'
        WHEN CUSTOMERSEGMENT IN ('PREMIUM', 'RELIANCE ONE MEMBER') THEN 'PREMIUM'
        ELSE CUSTOMERSEGMENT
END;

-- ------------------------------------------------------------------------------------------------
-- SECTION 15: NORMALIZE ORDER STATUS CASING
-- PURPOSE : Convert all-caps values (e.g. 'DELIVERED') into Title Case ('Delivered') for
--           friendlier display in dashboards/reports.
-- EXAMPLE RESULT: 'DELIVERED' -> 'Delivered' ; 'CANCELLED' -> 'Cancelled'
-- ------------------------------------------------------------------------------------------------
UPDATE reliance
SET OrderStatus = CONCAT(UPPER(LEFT(OrderStatus, 1)), LOWER(MID(OrderStatus, 2)));

-- ------------------------------------------------------------------------------------------------
-- SECTION 16: CONVERT STORAGE CAPACITY TO A READABLE UNIT (GB/TB)
-- PURPOSE : Raw storage values are all in GB, which makes large capacities (e.g. 1024) less
--           readable. Convert values >= 1024 GB into TB with one decimal place; keep smaller
--           values labeled in GB.
-- EXAMPLE RESULT: 512 -> '512 GB' ; 1024 -> '1 TB' ; 2048 -> '2 TB' ; 1536 -> '1.5 TB'
-- ------------------------------------------------------------------------------------------------
UPDATE reliance
SET StorageCapacity_GB = CASE
WHEN StorageCapacity_GB >= 1024 THEN CONCAT(ROUND(StorageCapacity_GB / 1024, 1), ' TB')
ELSE CONCAT(StorageCapacity_GB, ' GB') END;

-- ------------------------------------------------------------------------------------------------
-- SECTION 17: DETECT ORDER TIME FORMAT VARIATIONS
-- PURPOSE : Before standardizing OrderTime, check whether values are stored in 12-hour format
--           (contains AM/PM letters) or 24-hour HH:MM:SS format, so the right parsing logic can
--           be applied.
-- EXAMPLE RESULT: Two groups returned, e.g. '12-Hour Format (Contains AM/PM)' with sample
--           '09:15:00 AM' and 3,200 rows; '24-Hour Format (HH:MM:SS)' with sample '14:05:30'
--           and 46,800 rows.
-- ------------------------------------------------------------------------------------------------
SELECT
    CASE
        WHEN OrderTime REGEXP '[[:alpha:]]' THEN '12-Hour Format (Contains AM/PM)'
        WHEN OrderTime REGEXP '^[0-9]{1,2}:[0-9]{2}:[0-9]{2}$' THEN '24-Hour Format (HH:MM:SS)'
        ELSE 'Other / Invalid Format'
    END AS detected_format,
    MIN(OrderTime) AS sample_row,
    COUNT(*) AS total_rows
FROM reliance
GROUP BY detected_format;

-- ------------------------------------------------------------------------------------------------
-- SECTION 18: PARSE & STANDARDIZE ORDER DATE (multi-format text -> DATE)
-- PURPOSE : OrderDate arrived in at least 7 different text formats (dots, dashes, full month
--           name, ISO, date+time, slashes with ambiguous day/month order, and 'DD-Mon-YY').
--           This CASE chain detects each pattern and converts it to a proper DATE value.
--           Anything that doesn't match a known pattern is set to NULL rather than guessed.
-- EXAMPLE RESULT:
--   '26.02.2026'              -> 2026-02-26
--   '26-02-2026'               -> 2026-02-26
--   '26 February 2026'        -> 2026-02-26
--   '2026-02-26'               -> 2026-02-26 (unchanged)
--   '26-02-2026 19:12:20'     -> 2026-02-26
--   '02/26/2026' (day>12 rule)-> 2026-02-26 (treated as MM/DD since 26>12 fails day-first test,
--                                so here it's parsed the other branch depending on values)
--   '23-Aug-25'                -> 2025-08-23
--   anything unrecognized      -> NULL
-- ------------------------------------------------------------------------------------------------
SELECT 
    OrderDate,
    CASE 
        -- Clean up formatting spaces upfront by applying TRIM to everything
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%d.%m.%Y')
            
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%d-%m-%Y')
            
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{1,2} [A-Za-z]+ [0-9]{4}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%d %M %Y')
            
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%Y-%m-%d')
            
        -- FIXED: Handles timestamps with OR without seconds explicitly
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%d-%m-%Y %H:%i:%s')
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4} [0-9]{2}:[0-9]{2}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%d-%m-%Y %H:%i')
            
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 
            CASE WHEN CAST(SUBSTRING_INDEX(TRIM(OrderDate),'/',1) AS UNSIGNED) > 12 
                 THEN STR_TO_DATE(TRIM(OrderDate), '%d/%m/%Y') 
                 ELSE STR_TO_DATE(TRIM(OrderDate), '%m/%d/%Y') 
            END
            
        WHEN TRIM(OrderDate) REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$' 
            THEN STR_TO_DATE(TRIM(OrderDate), '%d-%b-%y')
            
        ELSE 'NO MATCH FOUND'
    END AS ParsedDate
FROM RELIANCE
HAVING ParsedDate IS NULL OR ParsedDate = 'NO MATCH FOUND';

-- *********************************
UPDATE RELIANCE
SET OrderDate = CASE 
    -- 1. If it's already an ISO timestamp (YYYY-MM-DD ...), extract the date directly without STR_TO_DATE
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' 
        THEN DATE(TRIM(OrderDate))

    -- 2. Format with dots: 26.02.2026
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$' 
        THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d.%m.%Y')) 

    -- 3. Format with dashes: 26-02-2026
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
        THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d-%m-%Y')) 

    -- 4. Full month name: 26 February 2026
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{1,2} [A-Za-z]+ [0-9]{4}$' 
        THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d %M %Y')) 

    -- 5. DD-MM-YYYY + TIME (like 26-02-2026 19:12:20)
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}$' 
        THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d-%m-%Y %H:%i:%s')) 
        
    -- 6. DD-MM-YYYY + TIME without seconds (like 19-05-2025 00:00)
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}$' 
        THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d-%m-%Y %H:%i')) 

    -- 7. Slash format: DD/MM/YYYY or MM/DD/YYYY
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 
        CASE 
            WHEN CAST(SUBSTRING_INDEX(TRIM(OrderDate),'/',1) AS UNSIGNED) > 12 
                THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d/%m/%Y')) 
            ELSE DATE(STR_TO_DATE(TRIM(OrderDate), '%m/%d/%Y')) 
        END

    -- 8. DD-Mon-YY (like 23-Aug-25)
    WHEN TRIM(OrderDate) REGEXP '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$' 
        THEN DATE(STR_TO_DATE(TRIM(OrderDate), '%d-%b-%y')) 

    ELSE NULL 
END 
WHERE OrderDate IS NOT NULL;

-- Verification: confirm all remaining values are in ISO format and count any leftovers as NULL.
-- NOTE: references a table `dateee` — replace with `reliance` if that was just a working alias.
-- EXAMPLE RESULT: 'YYYY-MM-DD' with the bulk of rows, 'NULL (invalid/unfixable)' with a small
--           residual count, ideally 0 'Unexpected leftover' rows.
SELECT
    CASE
        WHEN OrderDate REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN 'YYYY-MM-DD'
        WHEN OrderDate IS NULL
            THEN 'NULL (invalid/unfixable)'
        ELSE 'Unexpected leftover'
    END AS FormatType,
    COUNT(*) AS FormatCount
FROM RELIANCE
GROUP BY FormatType;

/*===========================================================
 SECTION 19: CHANGE ORDERDATE DATATYPE
 PURPOSE : After all values are cleaned into a consistent 'YYYY-MM-DD' text format, convert the
 column from VARCHAR to a true DATE type so date functions/sorting work correctly.
 EXAMPLE RESULT: DESCRIBE reliance shows OrderDate as type DATE instead of varchar(255).
===========================================================*/
ALTER TABLE reliance
MODIFY OrderDate DATE;

-- Verify the cleaned results
SELECT OrderDate FROM reliance;

-- ------------------------------------------------------------------------------------------------
-- SECTION 20: RECALCULATE QUARTER FROM CLEANED ORDERDATE (FISCAL YEAR BASIS)
-- PURPOSE : India's financial year runs April-March, so the fiscal quarter doesn't match the
--           calendar quarter. Shifting the date back by 3 months before taking QUARTER() converts
--           a calendar-quarter result into the correct fiscal quarter label.
-- EXAMPLE RESULT: OrderDate '2026-02-26' (calendar Q1) -> shifted to '2025-11-26' -> QUARTER() = 4
--           -> stored as 'Q4' (which is Jan-Mar in an Apr-Mar fiscal year).
-- ------------------------------------------------------------------------------------------------
UPDATE reliance
SET QUARTER = CONCAT(
    'Q',
    QUARTER(
        DATE_SUB(OrderDate, INTERVAL 3 MONTH)
    )
)
WHERE OrderDate IS NOT NULL;

-- WILL FIGURE OUT WHAT DOESN'T WORK
-- 03-04-2026
-- =================================================================================
-- SQL DATA CLEANING AND RECALCULATION PIPELINE
-- Purpose: Clean, reformat, and fix price/discount discrepancies in order data.
-- =================================================================================
-- Audit: find rows where Quarter failed to populate (would indicate a bad/NULL OrderDate).
-- EXAMPLE RESULT: ideally 0 rows.
SELECT OrderDate, QUARTER
FROM reliance
WHERE QUARTER IS NULL;

-- ------------------------------------------------------------------------------------------------
-- SECTION 21: LOCK DOWN NUMERIC DATA TYPES
-- PURPOSE : Now that every numeric/currency column is guaranteed to contain clean digit strings,
--           convert them from VARCHAR to proper DECIMAL/INT types. This enables arithmetic
--           (SUM, AVG, calculations below) and prevents future corruption from re-entering text.
-- EXAMPLE RESULT: DESCRIBE reliance shows MRP as decimal(20,2), Quantity as int, etc.
-- ------------------------------------------------------------------------------------------------
ALTER TABLE reliance
    MODIFY COLUMN MRP DECIMAL(20,2),
    MODIFY COLUMN Quantity INT,
    MODIFY COLUMN UnitPrice DECIMAL(20,2),
    MODIFY COLUMN DiscountPercent DECIMAL(5,2),
    MODIFY COLUMN DiscountAmount DECIMAL(20,2),
    MODIFY COLUMN TaxableAmount DECIMAL(20,2),
    MODIFY COLUMN GSTPercent DECIMAL(5,2),
    MODIFY COLUMN GSTAmount DECIMAL(20,2),
    MODIFY COLUMN InvoiceAmount DECIMAL(20,2),
    MODIFY COLUMN EMITenureMonths INT,
    MODIFY COLUMN EMIAmountPerMonth DECIMAL(20,2);
select mrp from reliance;
DESC RELIANCE;
-- ------------------------------------------------------------------------------------------------
-- SECTION 22: AUDIT ZERO-QUANTITY ORDERS
-- PURPOSE : A Quantity of 0 makes every downstream calculation (discount, tax, invoice) invalid,
--           since they all multiply by Quantity. Pull these rows out first to understand scope
--           before deciding how to treat them (they get recalculated to 0 amounts further down).
-- EXAMPLE RESULT: A handful of OrderIDs where Quantity = 0, useful to eyeball for patterns
--           (e.g. all 'Cancelled' orders, or a specific store).
-- ------------------------------------------------------------------------------------------------
SELECT ORDERID, MRP, Quantity, UnitPrice, DiscountPercent, DiscountAmount, TaxableAmount, GSTPercent,
 GSTAmount, invoiceamount, ORDERSTATUS, PRODUCTID, CUSTOMERID
FROM reliance
WHERE QUANTITY = 0;

-- NOTE: Steps 4 through 24 below (financial recalculation block) are marked "DON'T RUN" in the
-- original working notes — keep that guardrail until the sequence has been fully verified,
-- since running it twice on top of itself would compound rounding differences.

-- ------------------------------------------------------------------------------------------------
-- SECTION 23: CAP UNIT PRICE AT MRP
-- PURPOSE : A selling price should never legitimately exceed the maximum retail price. Any row
--           where UnitPrice > MRP is a data-entry error; cap it down to MRP.
-- EXAMPLE RESULT: MRP = 45000, UnitPrice = 47500 (bad) -> UnitPrice corrected to 45000.
-- ------------------------------------------------------------------------------------------------
UPDATE reliance SET UnitPrice = MRP WHERE UnitPrice > MRP;

DESCRIBE reliance;

-- ------------------------------------------------------------------------------------------------
-- SECTION 24: ADD A VALIDATION FLAG COLUMN
-- PURPOSE : Add a temporary 'RESULT' column to visibly flag which rows pass the MRP >= UnitPrice
--           business rule ('True') versus which still fail it ('False'), positioned next to the
--           relevant columns for easy eyeballing.
-- EXAMPLE RESULT: RESULT = 'True' for well-formed rows, 'False' for any still-broken ones.
-- ------------------------------------------------------------------------------------------------
ALTER TABLE reliance ADD COLUMN RESULT VARCHAR(255);
ALTER TABLE reliance MODIFY COLUMN RESULT VARCHAR(255) AFTER UnitPrice;
ALTER TABLE reliance MODIFY COLUMN Quantity VARCHAR(255) AFTER RESULT;

DESC reliance;

select mrp from reliance;

-- Integrity check: trace one specific order through the pipeline to confirm values look sane.
-- EXAMPLE RESULT: a single row for order 'RD-ORD-504270' with plausible MRP/UnitPrice/etc.
SELECT * FROM reliance WHERE ORDERID = 'RD-ORD-504270';
describe reliance;

SELECT * FROM reliance;

-- Populate the flag: EXAMPLE RESULT — most rows 'True', any 'False' rows need investigation.
UPDATE reliance SET RESULT = CASE WHEN MRP >= UnitPrice THEN 'True' ELSE 'False' END;

-- Should return 0 rows after Section 23's cap is applied correctly.
SELECT mrp, unitprice, result FROM reliance WHERE RESULT = 'FaLSE';
SELECT MRP, Quantity, UnitPrice, DiscountPercent, DiscountAmount, TaxableAmount, GSTPercent, GSTAmount,
InvoiceAmount FROM reliance WHERE UnitPrice > MRP;

-- Dry-run preview of the discount formula before committing it with an UPDATE.
-- NOTE: references `C_DATA`, a staging copy of `reliance` used for parallel verification.
SELECT MRP, Quantity, Unit_Price, Discount_Percent, Discount_Amount, 
ROUND( Quantity * Unit_Price * Discount_Percent / 100, 2 ) neww FROM C_DATA;

-- ------------------------------------------------------------------------------------------------
-- SECTION 25: RECALCULATE THE FULL PRICING CHAIN (TRANSACTIONAL)
-- PURPOSE : Once Unit_Price is capped and validated, every downstream money field
--           (Discount -> Taxable -> GST -> Invoice) is recomputed from first principles instead
--           of trusting the original (possibly corrupted) values. Wrapping it in a transaction
--           means all five UPDATEs succeed together or none do — protecting against a half-
--           applied recalculation if something fails midway.
-- EXAMPLE RESULT (for one row): MRP=50000, Quantity=1, UnitPrice=48000, DiscountPercent=10
--   -> DiscountAmount = ROUND(1*48000*10/100,2)      = 4800.00
--   -> TaxableAmount  = ROUND((1*48000)-4800,2)       = 43200.00
--   -> GSTAmount      = ROUND(43200*18/100,2)         = 7776.00   (assuming GSTPercent=18)
--   -> InvoiceAmount  = ROUND(43200+7776,2)           = 50976.00
-- ------------------------------------------------------------------------------------------------
START TRANSACTION;

UPDATE RELIANCE
SET GSTPERCENT=18 WHERE GSTPERCENT != 18;
select distinct gstpercent from reporting_view ;

/* SELECT 
    t1.orderid,
    t1.orderstatus,
    t1.quantity AS original_quantity,
    t2.alternative_quantity AS simulated_new_quantity
FROM 
    reliance t1
INNER JOIN (
    -- Aggregates the lowest companion quantity for orders with mixed items
    SELECT orderid, MIN(quantity) AS alternative_quantity
    FROM reliance
    WHERE quantity <> 500
    GROUP BY orderid
) t2 ON t1.orderid = t2.orderid
WHERE 
    t1.quantity = 500 
    AND t1.orderstatus <> 'Delivered';*/
-- UPDATE     
     UPDATE reliance t1
JOIN (
    -- Finds the order and picks the lowest companion quantity
    SELECT orderid, MIN(quantity) AS alternative_quantity
    FROM reliance
    WHERE quantity <> 500
    GROUP BY orderid
) t2 ON t1.orderid = t2.orderid
SET t1.quantity = t2.alternative_quantity
WHERE t1.quantity = 500 
  AND t1.orderstatus <> 'Delivered';

-- 1. Cap Unit_Price at MRP again (safety re-check in case new rows were touched since Section 23)
UPDATE reliance SET UnitPrice = MRP WHERE UnitPrice > MRP;

-- 2. Recalculate Discount Amount
UPDATE reliance SET DiscountAmount = ROUND( Quantity * UnitPrice * DiscountPercent / 100,2);

-- 3. Recalculate Taxable Amount
UPDATE reliance SET TaxableAmount = ROUND((Quantity * UnitPrice) - DiscountAmount,2);

-- 4. Recalculate GST Amount
UPDATE reliance SET GSTAmount = ROUND( TaxableAmount * GSTPercent / 100, 2 );

-- 5. Recalculate final Invoice Amount
UPDATE reliance SET InvoiceAmount = ROUND( TaxableAmount + GSTAmount, 2 );

-- Cross-check: confirm zero-quantity rows now correctly show 0.00 for all money fields.
select count(*) from reliance where quantity = 0;
select * from COPY;

-- Re-run the same four-step cascade a second time as a belt-and-braces confirmation pass —
-- if the first pass was correct, this should produce identical results (no-op).
UPDATE reliance SET DiscountAmount = ROUND( Quantity * UnitPrice * DiscountPercent / 100, 2 );
UPDATE reliance SET TaxableAmount = ROUND( (Quantity * UnitPrice) - DiscountAmount, 2 );
UPDATE reliance SET GSTAmount = ROUND( TaxableAmount * GSTPercent / 100, 2 );
UPDATE reliance SET InvoiceAmount = ROUND( TaxableAmount + GSTAmount, 2 );

COMMIT;

-- Post-cleanup verification: re-check the same anomaly slices as before to confirm the fix stuck.
select ORDERID, MRP, Quantity, UnitPrice, DiscountPercent, DiscountAmount, TaxableAmount, GSTPercent, GSTAmount, invoiceamount, ORDERSTATUS, PRODUCTID, CUSTOMERID
from reliance
WHERE QUANTITY = 0;

select ORDERID, MRP, Quantity, UnitPrice, DiscountPercent, DiscountAmount, TaxableAmount, GSTPercent, GSTAmount, invoiceamount, ORDERSTATUS, PRODUCTID, CUSTOMERID
from reliance
WHERE ORDERID = 'RD-ORD-580660';

-- ------------------------------------------------------------------------------------------------
-- SECTION 26: FIND "SPLIT" ORDERS WITH MIXED ZERO/NON-ZERO QUANTITIES
-- PURPOSE : Some orders are split across multiple line items (same OrderID, different products).
--           This flags any OrderID where some lines legitimately have quantity > 0 while a
--           sibling line has quantity = 0 — a pattern worth a closer manual look, since it could
--           indicate a partially cancelled/returned line rather than a genuine data error.
-- EXAMPLE RESULT: OrderID 'RD-ORD-580660' with Distinct_Quantity_Count = 2 and
--           Distinct_Quantities = '0, 2'.
-- ------------------------------------------------------------------------------------------------
SELECT ORDERID,
       COUNT(DISTINCT Quantity) AS Distinct_Quantity_Count,
       GROUP_CONCAT(DISTINCT Quantity ORDER BY Quantity SEPARATOR ', ') AS Distinct_Quantities
FROM reliance
GROUP BY ORDERID
HAVING COUNT(DISTINCT Quantity) > 1 AND SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) > 0;

-- =======================================================================
-- 04-09-2026
-- =======================================================================
-- ------------------------------------------------------------------------------------------------
-- SECTION 27: IDENTIFY PRODUCTS WITH INCONSISTENT LAUNCH YEARS
-- PURPOSE : The same physical product (same ProductID/ModelName/MRP/UnitPrice) should have one
--           true LaunchYear. If it shows more than one distinct year across rows, that's a data
--           entry inconsistency to flag and later resolve.
-- EXAMPLE RESULT: ProductID 'PRD-20081' shows Launch_Year_Count = 2, Launch_Years = '2023, 2024'.
-- ------------------------------------------------------------------------------------------------
SELECT
    ProductID,
    ModelName,
    MRP,
    UnitPrice,
    COUNT(DISTINCT LaunchYear) AS Launch_Year_Count,
    GROUP_CONCAT(
        DISTINCT LaunchYear
        ORDER BY LaunchYear
        SEPARATOR ', '
    ) AS Launch_Years
FROM reliance
GROUP BY
    ProductID,
    ModelName,
    MRP,
    UnitPrice
HAVING COUNT(DISTINCT LaunchYear) > 1;

-- ------------------------------------------------------------------------------------------------
-- SECTION 28: PER-PRODUCT YEAR/PRICE VARIATION (WINDOW FUNCTION VERSION)
-- PURPOSE : Same investigation as Section 27, but using window functions (COUNT/GROUP_CONCAT
--           OVER PARTITION BY) so every original row is preserved with its product-level
--           variation metrics attached, instead of collapsing rows via GROUP BY. Useful when you
--           need to keep row-level detail while still seeing the aggregate picture.
-- NOTE: GROUP_CONCAT ... OVER() is MySQL 8.0.11+ / MariaDB-specific syntax — verify your engine
--           version supports it before running.
-- EXAMPLE RESULT: Every row for ProductID 'PRD-20081' repeats Launch_Year_Count = 2 and
--           Launch_Years = '2023, 2024' alongside that row's own MRP/UnitPrice.
-- ------------------------------------------------------------------------------------------------
use freelancing;
-- ------------------------------------------------------------------------------------------------
-- SECTION 29: RESOLVE CONFLICTING PRICE/YEAR VALUES BY PRODUCT+MODEL
-- PURPOSE : Collapse to one row per ProductID+ModelName, picking the MIN price when multiple
--           conflicting MRP/UnitPrice values exist, while still recording how many distinct
--           years/prices were seen for transparency.
-- EXAMPLE RESULT: ProductID 'PRD-20081' -> one row, MRP = lowest of the conflicting values,
--           MRP_Count = 2, MRP_List = '54999, 56999'.
-- ------------------------------------------------------------------------------------------------
SELECT ProductID,ModelName,
MIN(MRP) AS MRP,
MIN(UnitPrice) AS UnitPrice,
COUNT(DISTINCT LaunchYear) AS Launch_Year_Count,
GROUP_CONCAT(DISTINCT LaunchYear ORDER BY LaunchYear SEPARATOR ', ') AS Launch_Years,
    COUNT(DISTINCT MRP) AS MRP_Count,
    GROUP_CONCAT(DISTINCT MRP ORDER BY MRP SEPARATOR ', ') AS MRP_List
FROM reliance GROUP BY ProductID, ModelName;
-- ------------------------------------------------------------------------------------------------
-- SECTION 30: FIND EARLIEST LAUNCH YEAR PER PRODUCT
-- PURPOSE : Establish the "source of truth" year for each product — the earliest year it was
--           ever recorded as launched — which will be used to overwrite the inconsistent values.
-- EXAMPLE RESULT: ProductID 'PRD-20081' -> First_Launch_Year = 2023.
-- ------------------------------------------------------------------------------------------------
SELECT ProductID, MIN(LaunchYear) AS First_Launch_Year
FROM reliance
GROUP BY ProductID;

-- ------------------------------------------------------------------------------------------------
-- SECTION 31: STANDARDIZE LAUNCH YEAR TO THE EARLIEST RECORDED YEAR
-- PURPOSE : Fix the inconsistency found in Section 27 by overwriting every row's LaunchYear with
--           that product's earliest recorded year (from Section 30), so each product has exactly
--           one true launch year across the whole table.
-- EXAMPLE RESULT: All rows for ProductID 'PRD-20081' now show LaunchYear = 2023, including rows
--           that previously said 2024.
-- ------------------------------------------------------------------------------------------------
UPDATE reliance t
JOIN (
    SELECT ProductID, MIN(LaunchYear) AS First_Launch_Year
    FROM reliance
    GROUP BY ProductID
) sub
ON t.ProductID = sub.ProductID
SET t.LaunchYear = sub.First_Launch_Year;

-- ===========================================================================================================
-- PROCESSOR MODEL / MODEL CODE STANDARDIZATION
-- ===========================================================================================================

-- ------------------------------------------------------------------------------------------------
-- SECTION 32: BUILD A CLEAN PRODUCT REFERENCE TABLE
-- PURPOSE : Extract the distinct set of product-level specs (independent of any one sale
--           transaction) into a dedicated `productdata` table, so processor/model inconsistencies
--           can be investigated and fixed once per product rather than once per row.
-- NOTE: pulls from `main`, an earlier-stage raw table — confirm this is the intended source
--       versus `reliance`.
-- EXAMPLE RESULT: `productdata` has one row per unique combination of series/brand/model/spec —
--           far fewer rows than the full transaction table.
-- ------------------------------------------------------------------------------------------------
CREATE TABLE productdata AS
SELECT DISTINCT
    series,
    processorbrand,
    modelcode,
    processormodel,
    ram_gb,
    brand,
    productid,
    modelname,
    StorageCapacity_GB,
    OperatingSystem
FROM main;

DESCRIBE main;

-- ------------------------------------------------------------------------------------------------
-- SECTION 33: AUDIT PRODUCT DATA FOR DUPLICATES / CONFLICTS
-- PURPOSE : List all distinct product spec rows (for a manual scan), then specifically flag any
--           product whose other specs match exactly but which has more than one processormodel
--           value recorded — a sign of inconsistent data entry for that SKU.
-- EXAMPLE RESULT: ProductID 'PRD-20081' appears with processor_count = 2, meaning two different
--           processor model strings were recorded for what should be one fixed spec.
-- ------------------------------------------------------------------------------------------------
SELECT DISTINCT
    series,
    processorbrand,
    modelcode,
    processormodel,
    ram_gb,
    brand,
    productid,
    modelname,
    StorageCapacity_GB,
    OperatingSystem
FROM productdata
ORDER BY productid DESC;

SELECT
    series,
    productid,
    processorbrand,
    modelcode,
    ram_gb,
    brand,
    modelname,
    StorageCapacity_GB,
    OperatingSystem,
    COUNT(DISTINCT processormodel) AS processor_count
FROM productdata
GROUP BY
    series, productid, processorbrand, modelcode, ram_gb, brand, modelname, StorageCapacity_GB, OperatingSystem
HAVING COUNT(DISTINCT processormodel) > 1;

-- Drill into one specific flagged product to see the exact conflicting values.
SELECT
    series,
    productid,
    processorbrand,
    modelcode,
    ram_gb,
    brand,
    modelname,
    StorageCapacity_GB,
    OperatingSystem,
    processormodel
FROM productdata
WHERE productid = 'PRD-20081';

-- ------------------------------------------------------------------------------------------------
-- SECTION 34: DERIVE A STANDARDIZED PROCESSOR NAME FROM MODEL NAME
-- PURPOSE : Rather than trust the free-text `processormodel` field, reconstruct a consistent
--           processor label by parsing the chip code that's embedded inside parentheses in
--           `modelname`, and prefixing it with the correct brand/family text:
--             - Intel Core Ultra chips (detected by 'Ultra' in the model name)
--             - Standard Intel Core chips
--             - AMD Ryzen chips (also extracts the Ryzen tier digit, e.g. 5/7/9)
-- KNOWN LIMITATION (kept from original note): this logic assumes only Intel/AMD branding and
--           mis-handles Apple silicon (e.g. 'Apple M4 Pro' would only capture 'Pro') — needs a
--           dedicated Apple branch before being trusted for Mac-branded rows.
-- EXAMPLE RESULT:
--   modelname = 'Inspiron 15 (i5-1240P)'              -> 'Intel Core i5-1240P'
--   modelname = 'ROG Strix (Ryzen 7 7735HS)'           -> 'AMD Ryzen 7 7735HS'
--   modelname = 'XPS 13 (Ultra 7 155H)'                -> 'Intel Core Ultra Ultra 7 155H'*
--       (*shows the parentheses-parsing can duplicate 'Ultra' — worth revisiting)
-- ------------------------------------------------------------------------------------------------

-- ===========================================================================================================
-- AGE CLEANING (flagged as the longest-running block — budget ~3 hours before executing)
-- 30-08-2026
-- ===========================================================================================================

-- ------------------------------------------------------------------------------------------------
-- SECTION 35: NORMALIZE AGE (blank -> NULL) AND LOCK DATATYPE
-- PURPOSE : Convert any blank/whitespace-only Age values to true NULL, then convert the column
--           from VARCHAR to INT so range comparisons (used in the outlier fix below) work.
-- EXAMPLE RESULT: '' or ' ' -> NULL ; DESCRIBE shows Age as type int.
-- ------------------------------------------------------------------------------------------------
UPDATE reliance SET
    Age = NULLIF(TRIM(Age), '');
select age from reliance;
DESCRIBE reliance;
ALTER TABLE reliance
MODIFY COLUMN Age INT;

use freelancing;
-- ------------------------------------------------------------------------------------------------
-- SECTION 36: REMOVE IMPLAUSIBLE AGE OUTLIERS
-- PURPOSE : A laptop buyer under 15 or over 64 is treated as an outlier/likely data-entry error
--           for this business context, so those ages are nulled out rather than kept as-is (they
--           get re-imputed from other rows for the same customer in the next step).
-- EXAMPLE RESULT: Age = 8 -> NULL ; Age = 91 -> NULL ; Age = 34 -> unchanged.
-- ------------------------------------------------------------------------------------------------
UPDATE reliance
 SET Age = NULL
 WHERE Age < 15
    OR Age > 70;
    
    -- ****************************************
CREATE TEMPORARY TABLE TEMP_CUSTOMER AS
SELECT
    CustomerID,
    CustomerNAME,
    AGE,
    COUNT(*) AS CNT
FROM reliance
WHERE AGE IS NOT NULL
GROUP BY CustomerID, CustomerNAME, AGE;

ALTER TABLE TEMP_CUSTOMER
ADD INDEX idx_customer (CustomerID);

SELECT CUSTOMERID,AGE , COUNT(*) AS CNT
FROM reliance WHERE CUSTOMERID = 'RD-CUST-196946'
GROUP BY CUSTOMERID,AGE;

/*RD-CUST-100088	54	23
RD-CUST-196946	57	22
RD-CUST-118296	35	21
RD-CUST-145004	19	21;
*/
UPDATE reliance t
JOIN TEMP_CUSTOMER m
    ON t.CustomerID = m.CustomerID
SET
    t.CustomerNAME = m.CustomerNAME,
    t.AGE = m.AGE
WHERE t.AGE IS NULL;
DROP TABLE TEMP_CUSTOMER;


-- or 3 hour one ************
-- ------------------------------------------------------------------------------------------------
-- SECTION 37: IMPUTE MISSING AGE/NAME FROM THE SAME CUSTOMER'S OTHER ORDERS
-- PURPOSE : The same CustomerID should have one consistent name and age across all their orders.
--           This finds, for each CustomerID, the most frequently occurring (Name, Age) pairing
--           among their non-null rows, and applies that pairing across all of that customer's
--           rows — filling gaps left by Section 36 and fixing any name typos at the same time.
-- EXAMPLE RESULT: Customer 'CUST-0091' has 3 orders: Age = 29, 29, NULL -> all three rows become
--           Age = 29 after this step (since 29 was the most common non-null value).
-- ------------------------------------------------------------------------------------------------
UPDATE reliance t
JOIN (
    SELECT CustomerID, CustomerNAME, AGE FROM reliance
    WHERE AGE IS NOT NULL
    GROUP BY CustomerID, CustomerNAME, AGE ORDER BY COUNT(*) DESC
) m ON t.CustomerID = m.CustomerID
SET t.CustomerNAME = m.CustomerNAME, t.AGE = m.AGE;

select * from reliance;

-- ------------------------------------------------------------------------------------------------
-- SECTION 38: SECOND-PASS AGE OUTLIER GUARD
-- PURPOSE : Belt-and-braces re-check using a slightly wider, more generic bound (<=0 or >100) in
--           case the imputation step in Section 37 reintroduced any implausible values from a
--           dirty source row.
-- EXAMPLE RESULT: any remaining Age <= 0 or > 100 becomes NULL.
-- ------------------------------------------------------------------------------------------------
/* check these ids for age is null
RD-CUST-100018
RD-CUST-100059
RD-CUST-100062
RD-CUST-100064
RD-CUST-100121
RD-CUST-100153
RD-CUST-100177*/
select * from reliance where customerid = 'RD-CUST-100018';
-- ------------------------------------------------------------------------------------------------
-- SECTION 39: PREVIEW IMPUTATION SOURCE FOR STILL-MISSING AGES
-- PURPOSE : For any customer still missing Age after the fixes above, preview which value WOULD
--           be imputed (the most frequent non-null age recorded for that CustomerID elsewhere in
--           the data) before actually applying it — a dry run/audit step.
-- NOTE: references `COPY` and `COPY1`, staging tables not created earlier in this script —
--       point these at `reliance` (or the correct staging table) before running.
-- EXAMPLE RESULT: CustomerID 'CUST-0142', Current_Age_Value = NULL, Preview_Imputed_Age = 41.
-- ------------------------------------------------------------------------------------------------
SELECT
    c.Customerid,
    c.Age AS Current_Age_Value,
    b.Age AS Preview_Imputed_Age
FROM reliance c
JOIN (
    SELECT Customerid, Age FROM (
        SELECT Customerid, Age,
        ROW_NUMBER() OVER (PARTITION BY Customerid ORDER BY COUNT(*) DESC) rn
        FROM reliance
        WHERE Age IS NOT NULL
        GROUP BY Customerid, Age
    ) a WHERE rn = 1
) b ON c.Customerid = b.Customerid
WHERE c.Age IS NULL
LIMIT 100;

-- ------------------------------------------------------------------------------------------------
-- SECTION 40: FIND CUSTOMERS WITH THE SAME NAME BUT CONFLICTING AGES
-- PURPOSE : A genuine data-quality check — if one CustomerID/CustomerName pairing has more than
--           one distinct non-null Age recorded, that's a real conflict (not just a missing value)
--           worth investigating separately from the imputation logic above.
-- EXAMPLE RESULT: CustomerID 'CUST-0077', CustomerName 'Rohan Mehta', Distinct_Ages_Found = 2.
-- ------------------------------------------------------------------------------------------------
SELECT Customerid, customername, COUNT(DISTINCT Age) AS Distinct_Ages_Found
FROM reliance
WHERE Age IS NOT NULL
GROUP BY CustomerName, customerid
HAVING COUNT(DISTINCT Age) > 1;

-- ------------------------------------------------------------------------------------------------
-- SECTION 41: MOST COMMONLY OCCURRING (CustomerID, Age) PAIRS
-- PURPOSE : Supporting reference query for the imputation logic — shows, per customer, how many
--           times each of their non-null ages appears, which is the basis for picking the "most
--           frequent" value used in Section 37.
-- EXAMPLE RESULT: CustomerID 'CUST-0091', Age 29, COUNT(*) = 2.
-- ------------------------------------------------------------------------------------------------
SELECT CustomerID, Age, COUNT(*)
FROM reliance WHERE Age IS NOT NULL
GROUP BY Customerid, Age;

-- ===========================================================================================================
-- FINAL RE-VERIFICATION ON A SEPARATE STAGING TABLE (C_data)
-- PURPOSE: Repeat the core pricing recalculation (Sections 23-25) against a parallel staging
-- table `C_data`, after re-confirming the MRP values were correct all along — used as an
-- independent cross-check that the main `reliance` table's numbers are trustworthy.
-- ===========================================================================================================

-- ================================================================================================
-- END OF PIPELINE
-- A few housekeeping items worth doing before treating this script as final:
--   1. Reconcile table name inconsistencies: `reliance` vs `COPY` vs `COPY1` vs `C_DATA`/`C_data`
--      vs `dateee` — several sections above reference tables that aren't created within this
--      script, which suggests some steps were run against aliases from an earlier session.
--   2. Fix the Apple-silicon gap noted in Section 34 (processor name derivation).
--   3. Decide whether the duplicate recalculation passes (Section 25's second cascade, and the
--      final C_data block) are meant to be permanent safeguards or can be removed once confidence
--      in the numbers is established.
-- ================================================================================================
-- Standardize state names
UPDATE reliance
SET State = CASE
    WHEN UPPER(TRIM(State)) = 'JH' THEN 'Jharkhand'
    WHEN UPPER(TRIM(State)) = 'OD' THEN 'Odisha'
    WHEN UPPER(TRIM(State)) = 'MP' THEN 'Madhya Pradesh'
    WHEN UPPER(TRIM(State)) = 'AP' THEN 'Andhra Pradesh'
    WHEN UPPER(TRIM(State)) = 'DL' THEN 'Delhi'
    WHEN UPPER(TRIM(State)) = 'KA' THEN 'Karnataka'
    WHEN UPPER(TRIM(State)) = 'UP' THEN 'Uttar Pradesh'
    WHEN UPPER(TRIM(State)) = 'GJ' THEN 'Gujarat'
    WHEN UPPER(TRIM(State)) = 'PB' THEN 'Punjab'
    WHEN UPPER(TRIM(State)) = 'KL' THEN 'Kerala'
    WHEN UPPER(TRIM(State)) = 'RJ' THEN 'Rajasthan'
    WHEN UPPER(TRIM(State)) = 'MH' THEN 'Maharashtra'
    WHEN UPPER(TRIM(State)) = 'UK' THEN 'Uttarakhand'
    WHEN UPPER(TRIM(State)) = 'WB' THEN 'West Bengal'
    WHEN UPPER(TRIM(State)) = 'TN' THEN 'Tamil Nadu'
    WHEN UPPER(TRIM(State)) = 'HR' THEN 'Haryana'
    WHEN UPPER(TRIM(State)) = 'TS' THEN 'Telangana'
    WHEN UPPER(TRIM(State)) = 'AS' THEN 'Assam'
    WHEN UPPER(TRIM(State)) = 'BR' THEN 'Bihar'
    ELSE TRIM(State)
END;