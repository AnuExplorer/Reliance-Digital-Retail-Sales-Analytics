-- =====================================================================
-- base_view_123: everything now comes from ONE table, Order123
-- (previously Order_i + Price joined on OrderID; no join needed now)
-- =====================================================================
CREATE OR REPLACE VIEW base_view_123 AS
SELECT
    o.OrderID, o.OrderDate, o.OrderTime,
    o.FinancialYear, o.Quarter,
    o.CustomerID, o.ProductID, o.StoreID,
    o.MRP, o.Quantity, o.UnitPrice,
    o.DiscountPercent, o.DiscountAmount,
    o.TaxableAmount, o.GSTPercent, o.GSTAmount, o.InvoiceAmount,
    o.PaymentMethod, o.EMITenureMonths, o.EMIAmountPerMonth,
    o.OrderStatus,
    o.DeliveryDate, o.DeliveryDays, o.ChannelType
FROM Order123 o;


-- =====================================================================
-- reportingview_123: base_view_123 + descriptive columns from the 3 dimensions
-- =====================================================================
CREATE OR REPLACE VIEW reportingview_123 AS
SELECT
    b.OrderID, b.OrderDate, b.OrderTime, b.FinancialYear, b.Quarter,
    -- customer
    b.CustomerID, c.CustomerName, c.Gender, c.Age, c.CustomerSegment,
    -- product
    b.ProductID,
    p.Brand, p.Series, p.ModelName, p.ModelCode, p.ProcessorBrand, p.ProcessorModel,
    p.RAM_GB, p.StorageType, p.StorageCapacity_GB, p.GraphicsCard, p.ScreenSize_inch,
    p.OperatingSystem, p.Color, p.LaunchYear, p.ProductCategory,
    -- money
    b.MRP, b.Quantity, b.UnitPrice, b.DiscountPercent, b.DiscountAmount,
    b.TaxableAmount, b.GSTPercent, b.GSTAmount, b.InvoiceAmount,
    b.PaymentMethod, b.EMITenureMonths, b.EMIAmountPerMonth,
    -- order / delivery
    b.OrderStatus, b.DeliveryDate, b.DeliveryDays, b.ChannelType,
    -- store
    b.StoreID, s.StoreName, s.StoreCity, s.StoreState, s.Region
FROM base_view_123 b
LEFT JOIN Customer    c ON c.CustomerID = b.CustomerID
LEFT JOIN Productdata p ON p.ProductID  = b.ProductID
LEFT JOIN Stor        s ON s.StoreID    = b.StoreID;

-- ===========================================================================================================================
-- Data quality check on reportingview_123, split in 5 parts.
-- Run one part at a time: click inside it and press Ctrl+Enter.
-- nulls = NULL values | blanks = empty text | untrimmed = extra spaces
-- bad_num = invalid numbers | distincts = unique values | min_val / max_val = range

-- ===== PART 1: Order identity and dates =====
SELECT 'OrderID' col,SUM(OrderID IS NULL) nulls,SUM(TRIM(OrderID)='') blanks,SUM(OrderID<>TRIM(OrderID)) untrimmed,0 bad_num,COUNT(DISTINCT OrderID) distincts,CAST(MIN(OrderID) AS CHAR) min_val,CAST(MAX(OrderID) AS CHAR) max_val FROM reportingview_123
UNION ALL SELECT 'OrderDate',SUM(OrderDate IS NULL),0,0,0,COUNT(DISTINCT OrderDate),CAST(MIN(OrderDate) AS CHAR),CAST(MAX(OrderDate) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'OrderTime',SUM(OrderTime IS NULL),0,0,0,COUNT(DISTINCT OrderTime),CAST(MIN(OrderTime) AS CHAR),CAST(MAX(OrderTime) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'FinancialYear',SUM(FinancialYear IS NULL),SUM(TRIM(FinancialYear)=''),SUM(FinancialYear<>TRIM(FinancialYear)),0,COUNT(DISTINCT FinancialYear),CAST(MIN(FinancialYear) AS CHAR),CAST(MAX(FinancialYear) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'Quarter',SUM(Quarter IS NULL),SUM(TRIM(Quarter)=''),SUM(Quarter<>TRIM(Quarter)),0,COUNT(DISTINCT Quarter),CAST(MIN(Quarter) AS CHAR),CAST(MAX(Quarter) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'CustomerID',SUM(CustomerID IS NULL),SUM(TRIM(CustomerID)=''),SUM(CustomerID<>TRIM(CustomerID)),0,COUNT(DISTINCT CustomerID),CAST(MIN(CustomerID) AS CHAR),CAST(MAX(CustomerID) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ProductID',SUM(ProductID IS NULL),SUM(TRIM(ProductID)=''),SUM(ProductID<>TRIM(ProductID)),0,COUNT(DISTINCT ProductID),CAST(MIN(ProductID) AS CHAR),CAST(MAX(ProductID) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'StoreID',SUM(StoreID IS NULL),SUM(TRIM(StoreID)=''),SUM(StoreID<>TRIM(StoreID)),0,COUNT(DISTINCT StoreID),CAST(MIN(StoreID) AS CHAR),CAST(MAX(StoreID) AS CHAR) FROM reportingview_123;

-- ===== PART 2: Customer =====
SELECT 'CustomerName' col,SUM(CustomerName IS NULL) nulls,SUM(TRIM(CustomerName)='') blanks,SUM(CustomerName<>TRIM(CustomerName)) untrimmed,0 bad_num,COUNT(DISTINCT CustomerName) distincts,CAST(MIN(CustomerName) AS CHAR) min_val,CAST(MAX(CustomerName) AS CHAR) max_val FROM reportingview_123
UNION ALL SELECT 'CustomerID',SUM(CustomerID IS NULL),SUM(TRIM(CustomerID)=''),SUM(CustomerID<>TRIM(CustomerID)),0,COUNT(DISTINCT CustomerID),CAST(MIN(CustomerID) AS CHAR),CAST(MAX(CustomerID) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'Gender',SUM(Gender IS NULL),SUM(TRIM(Gender)=''),SUM(Gender<>TRIM(Gender)),0,COUNT(DISTINCT Gender),CAST(MIN(Gender) AS CHAR),CAST(MAX(Gender) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'Age',SUM(Age IS NULL),0,0,SUM(Age<=0 OR Age>100),COUNT(DISTINCT Age),CAST(MIN(Age) AS CHAR),CAST(MAX(Age) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'CustomerSegment',SUM(CustomerSegment IS NULL),SUM(TRIM(CustomerSegment)=''),SUM(CustomerSegment<>TRIM(CustomerSegment)),0,COUNT(DISTINCT CustomerSegment),CAST(MIN(CustomerSegment) AS CHAR),CAST(MAX(CustomerSegment) AS CHAR) FROM reportingview_123;

-- ===== PART 3: Product =====
SELECT 'Brand' col,SUM(Brand IS NULL) nulls,SUM(TRIM(Brand)='') blanks,SUM(Brand<>TRIM(Brand)) untrimmed,0 bad_num,COUNT(DISTINCT Brand) distincts,CAST(MIN(Brand) AS CHAR) min_val,CAST(MAX(Brand) AS CHAR) max_val FROM reportingview_123
UNION ALL SELECT 'ProductID',SUM(ProductID IS NULL),SUM(TRIM(ProductID)=''),SUM(ProductID<>TRIM(ProductID)),0,COUNT(DISTINCT ProductID),CAST(MIN(ProductID) AS CHAR),CAST(MAX(ProductID) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'Series',SUM(Series IS NULL),SUM(TRIM(Series)=''),SUM(Series<>TRIM(Series)),0,COUNT(DISTINCT Series),CAST(MIN(Series) AS CHAR),CAST(MAX(Series) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ModelName',SUM(ModelName IS NULL),SUM(TRIM(ModelName)=''),SUM(ModelName<>TRIM(ModelName)),0,COUNT(DISTINCT ModelName),CAST(MIN(ModelName) AS CHAR),CAST(MAX(ModelName) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ModelCode',SUM(ModelCode IS NULL),SUM(TRIM(ModelCode)=''),SUM(ModelCode<>TRIM(ModelCode)),0,COUNT(DISTINCT ModelCode),CAST(MIN(ModelCode) AS CHAR),CAST(MAX(ModelCode) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ProcessorBrand',SUM(ProcessorBrand IS NULL),SUM(TRIM(ProcessorBrand)=''),SUM(ProcessorBrand<>TRIM(ProcessorBrand)),0,COUNT(DISTINCT ProcessorBrand),CAST(MIN(ProcessorBrand) AS CHAR),CAST(MAX(ProcessorBrand) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ProcessorModel',SUM(ProcessorModel IS NULL),SUM(TRIM(ProcessorModel)=''),SUM(ProcessorModel<>TRIM(ProcessorModel)),0,COUNT(DISTINCT ProcessorModel),CAST(MIN(ProcessorModel) AS CHAR),CAST(MAX(ProcessorModel) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'RAM_GB',SUM(RAM_GB IS NULL),0,0,SUM(RAM_GB<=0),COUNT(DISTINCT RAM_GB),CAST(MIN(RAM_GB) AS CHAR),CAST(MAX(RAM_GB) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'StorageType',SUM(StorageType IS NULL),SUM(TRIM(StorageType)=''),SUM(StorageType<>TRIM(StorageType)),0,COUNT(DISTINCT StorageType),CAST(MIN(StorageType) AS CHAR),CAST(MAX(StorageType) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'StorageCapacity_GB',SUM(StorageCapacity_GB IS NULL),0,0,SUM(StorageCapacity_GB<=0),COUNT(DISTINCT StorageCapacity_GB),CAST(MIN(StorageCapacity_GB) AS CHAR),CAST(MAX(StorageCapacity_GB) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'GraphicsCard',SUM(GraphicsCard IS NULL),SUM(TRIM(GraphicsCard)=''),SUM(GraphicsCard<>TRIM(GraphicsCard)),0,COUNT(DISTINCT GraphicsCard),CAST(MIN(GraphicsCard) AS CHAR),CAST(MAX(GraphicsCard) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ScreenSize_inch',SUM(ScreenSize_inch IS NULL),0,0,SUM(ScreenSize_inch<=0),COUNT(DISTINCT ScreenSize_inch),CAST(MIN(ScreenSize_inch) AS CHAR),CAST(MAX(ScreenSize_inch) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'OperatingSystem',SUM(OperatingSystem IS NULL),SUM(TRIM(OperatingSystem)=''),SUM(OperatingSystem<>TRIM(OperatingSystem)),0,COUNT(DISTINCT OperatingSystem),CAST(MIN(OperatingSystem) AS CHAR),CAST(MAX(OperatingSystem) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'Color',SUM(Color IS NULL),SUM(TRIM(Color)=''),SUM(Color<>TRIM(Color)),0,COUNT(DISTINCT Color),CAST(MIN(Color) AS CHAR),CAST(MAX(Color) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'LaunchYear',SUM(LaunchYear IS NULL),0,0,SUM(LaunchYear<=0),COUNT(DISTINCT LaunchYear),CAST(MIN(LaunchYear) AS CHAR),CAST(MAX(LaunchYear) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ProductCategory',SUM(ProductCategory IS NULL),SUM(TRIM(ProductCategory)=''),SUM(ProductCategory<>TRIM(ProductCategory)),0,COUNT(DISTINCT ProductCategory),CAST(MIN(ProductCategory) AS CHAR),CAST(MAX(ProductCategory) AS CHAR) FROM reportingview_123;

-- ===== PART 4: Pricing, tax, payment and EMI =====
SELECT 'MRP' col,SUM(MRP IS NULL) nulls,0 blanks,0 untrimmed,SUM(MRP<=0) bad_num,COUNT(DISTINCT MRP) distincts,CAST(MIN(MRP) AS CHAR) min_val,CAST(MAX(MRP) AS CHAR) max_val FROM reportingview_123
UNION ALL SELECT 'Quantity',SUM(Quantity IS NULL),0,0,SUM(Quantity<0),COUNT(DISTINCT Quantity),CAST(MIN(Quantity) AS CHAR),CAST(MAX(Quantity) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'UnitPrice',SUM(UnitPrice IS NULL),0,0,SUM(UnitPrice<=0),COUNT(DISTINCT UnitPrice),CAST(MIN(UnitPrice) AS CHAR),CAST(MAX(UnitPrice) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'DiscountPercent',SUM(DiscountPercent IS NULL),0,0,SUM(DiscountPercent<0 OR DiscountPercent>100),COUNT(DISTINCT DiscountPercent),CAST(MIN(DiscountPercent) AS CHAR),CAST(MAX(DiscountPercent) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'DiscountAmount',SUM(DiscountAmount IS NULL),0,0,SUM(DiscountAmount<0),COUNT(DISTINCT DiscountAmount),CAST(MIN(DiscountAmount) AS CHAR),CAST(MAX(DiscountAmount) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'TaxableAmount',SUM(TaxableAmount IS NULL),0,0,SUM(TaxableAmount<=0),COUNT(DISTINCT TaxableAmount),CAST(MIN(TaxableAmount) AS CHAR),CAST(MAX(TaxableAmount) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'GSTPercent',SUM(GSTPercent IS NULL),0,0,SUM(GSTPercent<0 OR GSTPercent>100),COUNT(DISTINCT GSTPercent),CAST(MIN(GSTPercent) AS CHAR),CAST(MAX(GSTPercent) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'GSTAmount',SUM(GSTAmount IS NULL),0,0,SUM(GSTAmount<0),COUNT(DISTINCT GSTAmount),CAST(MIN(GSTAmount) AS CHAR),CAST(MAX(GSTAmount) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'InvoiceAmount',SUM(InvoiceAmount IS NULL),0,0,SUM(InvoiceAmount<=0),COUNT(DISTINCT InvoiceAmount),CAST(MIN(InvoiceAmount) AS CHAR),CAST(MAX(InvoiceAmount) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'PaymentMethod',SUM(PaymentMethod IS NULL),SUM(TRIM(PaymentMethod)=''),SUM(PaymentMethod<>TRIM(PaymentMethod)),0,COUNT(DISTINCT PaymentMethod),CAST(MIN(PaymentMethod) AS CHAR),CAST(MAX(PaymentMethod) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'EMITenureMonths',SUM(EMITenureMonths IS NULL),0,0,SUM(EMITenureMonths<0),COUNT(DISTINCT EMITenureMonths),CAST(MIN(EMITenureMonths) AS CHAR),CAST(MAX(EMITenureMonths) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'EMIAmountPerMonth',SUM(EMIAmountPerMonth IS NULL),0,0,SUM(EMIAmountPerMonth<0),COUNT(DISTINCT EMIAmountPerMonth),CAST(MIN(EMIAmountPerMonth) AS CHAR),CAST(MAX(EMIAmountPerMonth) AS CHAR) FROM reportingview_123;

-- ===== PART 5: Order status, delivery and store =====
SELECT 'OrderStatus' col,SUM(OrderStatus IS NULL) nulls,SUM(TRIM(OrderStatus)='') blanks,SUM(OrderStatus<>TRIM(OrderStatus)) untrimmed,0 bad_num,COUNT(DISTINCT OrderStatus) distincts,CAST(MIN(OrderStatus) AS CHAR) min_val,CAST(MAX(OrderStatus) AS CHAR) max_val FROM reportingview_123
UNION ALL SELECT 'OrderID' col,SUM(OrderID IS NULL) nulls,SUM(TRIM(OrderID)='') blanks,SUM(OrderID<>TRIM(OrderID)) untrimmed,0 bad_num,COUNT(DISTINCT OrderID) distincts,CAST(MIN(OrderID) AS CHAR) min_val,CAST(MAX(OrderID) AS CHAR) max_val FROM reportingview_123
UNION ALL SELECT 'DeliveryDate',SUM(DeliveryDate IS NULL),0,0,0,COUNT(DISTINCT DeliveryDate),CAST(MIN(DeliveryDate) AS CHAR),CAST(MAX(DeliveryDate) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'DeliveryDays',SUM(DeliveryDays IS NULL),0,0,SUM(DeliveryDays<0),COUNT(DISTINCT DeliveryDays),CAST(MIN(DeliveryDays) AS CHAR),CAST(MAX(DeliveryDays) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'ChannelType',SUM(ChannelType IS NULL),SUM(TRIM(ChannelType)=''),SUM(ChannelType<>TRIM(ChannelType)),0,COUNT(DISTINCT ChannelType),CAST(MIN(ChannelType) AS CHAR),CAST(MAX(ChannelType) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'StoreName',SUM(StoreName IS NULL),SUM(TRIM(StoreName)=''),SUM(StoreName<>TRIM(StoreName)),0,COUNT(DISTINCT StoreName),CAST(MIN(StoreName) AS CHAR),CAST(MAX(StoreName) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'StoreCity',SUM(StoreCity IS NULL),SUM(TRIM(StoreCity)=''),SUM(StoreCity<>TRIM(StoreCity)),0,COUNT(DISTINCT StoreCity),CAST(MIN(StoreCity) AS CHAR),CAST(MAX(StoreCity) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'StoreState',SUM(StoreState IS NULL),SUM(TRIM(StoreState)=''),SUM(StoreState<>TRIM(StoreState)),0,COUNT(DISTINCT StoreState),CAST(MIN(StoreState) AS CHAR),CAST(MAX(StoreState) AS CHAR) FROM reportingview_123
UNION ALL SELECT 'Region',SUM(Region IS NULL),SUM(TRIM(Region)=''),SUM(Region<>TRIM(Region)),0,COUNT(DISTINCT Region),CAST(MIN(Region) AS CHAR),CAST(MAX(Region) AS CHAR) FROM reportingview_123;

-- ======= PART 6 :
-- ============================================================
-- PART 6: CROSS-COLUMN CHECKS on reportingview_123
-- Each row = one rule. violations should be 0.
-- Tolerance of 1 rupee is used for rounding. Change if needed.
-- Run each part by clicking inside it and pressing Ctrl+Enter.
-- ============================================================

SELECT 'UnitPrice > MRP' chk, SUM(UnitPrice > MRP) violations FROM reportingview_123
UNION ALL SELECT 'Taxable <> UnitPrice*Qty - DiscountAmount', SUM(ABS(UnitPrice*Quantity - DiscountAmount - TaxableAmount) > 1) FROM reportingview_123
UNION ALL SELECT 'GSTAmount <> Taxable*GST%/100', SUM(ABS(TaxableAmount*GSTPercent/100 - GSTAmount) > 1) FROM reportingview_123
UNION ALL SELECT 'Invoice <> Taxable + GST', SUM(ABS(TaxableAmount + GSTAmount - InvoiceAmount) > 1) FROM reportingview_123
UNION ALL SELECT 'DeliveryDate < OrderDate', SUM(DeliveryDate < OrderDate) FROM reportingview_123
UNION ALL SELECT 'DeliveryDays <> DATEDIFF(Delivery, Order)', SUM(DeliveryDays <> DATEDIFF(DeliveryDate, OrderDate)) FROM reportingview_123
UNION ALL SELECT 'EMI tenure > 0 but PaymentMethod not EMI', SUM(EMITenureMonths > 0 AND PaymentMethod NOT LIKE '%EMI%') FROM reportingview_123
UNION ALL SELECT 'PaymentMethod EMI but tenure = 0', SUM(EMITenureMonths = 0 AND PaymentMethod LIKE '%EMI%') FROM reportingview_123
UNION ALL SELECT 'EMI total differs from Invoice by > 20%', SUM(EMITenureMonths > 0 AND ABS(EMIAmountPerMonth*EMITenureMonths - InvoiceAmount) > 0.2*InvoiceAmount) FROM reportingview_123;


-- ============================================================================================================
-- 1. Which payment methods carry an EMI tenure?
SELECT PaymentMethod, EMITenureMonths > 0 AS has_emi, COUNT(*) rows_cnt
FROM reportingview_123 GROUP BY PaymentMethod, has_emi ORDER BY PaymentMethod, has_emi;

-- Cash rows with tenure: are they Quantity = 0 rows, or do they have a real EMI amount?
SELECT EMITenureMonths, (EMIAmountPerMonth > 0) has_amount, COUNT(*) cnt
FROM reportingview_123
WHERE PaymentMethod = 'Cash' AND EMITenureMonths > 0
GROUP BY 1, 2;

-- Compare those rows with the raw data (replace the OrderID with a real one from the first query)
SELECT * FROM RELIANCE WHERE OrderID = 'RD-ORD-xxxxxx';

-- The 254 EMI rows with no tenure: are they Quantity = 0 rows?
SELECT PaymentMethod, OrderStatus, COUNT(*) cnt
FROM reportingview_123
WHERE PaymentMethod LIKE 'EMI%' AND EMITenureMonths = 0
GROUP BY 1, 2;
-- 2. How big is the EMI total compared with the invoice, per tenure?
SELECT EMITenureMonths, COUNT(*) rows_cnt,
       ROUND(MIN(EMIAmountPerMonth*EMITenureMonths/InvoiceAmount),2) min_ratio,
       ROUND(AVG(EMIAmountPerMonth*EMITenureMonths/InvoiceAmount),2) avg_ratio,
       ROUND(MAX(EMIAmountPerMonth*EMITenureMonths/InvoiceAmount),2) max_ratio
FROM reportingview_123 WHERE EMITenureMonths > 0 GROUP BY EMITenureMonths ORDER BY EMITenureMonths;

SELECT EMITenureMonths,
       SUM(EMIAmountPerMonth = 0) AS zero_emi,
       SUM(EMIAmountPerMonth > 0 AND EMIAmountPerMonth*EMITenureMonths/InvoiceAmount < 0.95) AS below_invoice,
       SUM(EMIAmountPerMonth*EMITenureMonths/InvoiceAmount > 1.5) AS too_high
FROM reportingview_123
WHERE EMITenureMonths > 0
GROUP BY EMITenureMonths ORDER BY EMITenureMonths;

SELECT PaymentMethod, COUNT(*) zero_emi_rows
FROM reportingview_123
WHERE EMITenureMonths > 0 AND EMIAmountPerMonth = 0
GROUP BY PaymentMethod;

-- Does the implied tenure (Invoice / EMI amount) explain the odd rows?
SELECT EMITenureMonths, ROUND(InvoiceAmount/EMIAmountPerMonth) implied_tenure, COUNT(*) rows_cnt
FROM reportingview_123
WHERE EMITenureMonths > 0 AND EMIAmountPerMonth > 0
  AND (EMIAmountPerMonth*EMITenureMonths/InvoiceAmount < 0.95
       OR EMIAmountPerMonth*EMITenureMonths/InvoiceAmount > 1.5)
GROUP BY 1,2 ORDER BY 1,2;

-- For each payment method, how many rows have a tenure, and how many of those have an amount?
SELECT PaymentMethod,
       SUM(EMITenureMonths = 0) no_tenure,
       SUM(EMITenureMonths > 0) with_tenure,
       SUM(EMITenureMonths > 0 AND EMIAmountPerMonth > 0) with_tenure_and_amount
FROM reportingview_123 GROUP BY PaymentMethod;
-- ============================================================================================================================================================
SELECT PaymentMethod, SUM(EMITenureMonths > 0) with_tenure
FROM reportingview_123 WHERE PaymentMethod NOT LIKE 'EMI%' GROUP BY PaymentMethod;

SELECT EMITenureMonths, COUNT(*) rows_cnt FROM price GROUP BY EMITenureMonths ORDER BY rows_cnt DESC LIMIT 25;
SELECT SUM(EMIAmountPerMonth = 'NOT AVAILABLE') amt_not_avail, COUNT(*) total FROM ORDER123;


-- 3. The 254 suspicious rows
SELECT PaymentMethod, EMITenureMonths, EMIAmountPerMonth, COUNT(*) rows_cnt
FROM reportingview_123
WHERE PaymentMethod LIKE '%EMI%' AND EMITenureMonths = 0
GROUP BY PaymentMethod, EMITenureMonths, EMIAmountPerMonth;

-- =============================================================================================
-- Mapping checks: each ID must map to exactly one name. Expect 0 rows.
SELECT 'StoreID' id_col, StoreID id_val, COUNT(DISTINCT StoreName) names, COUNT(DISTINCT StoreCity) cities FROM reportingview_123 GROUP BY StoreID HAVING names > 1 OR cities > 1;
SELECT 'ProductID' id_col, ProductID id_val, COUNT(DISTINCT ModelName) names, COUNT(DISTINCT ModelCode) codes FROM reportingview_123 GROUP BY ProductID HAVING names > 1 OR codes > 1;
SELECT 'CustomerID' id_col, CustomerID id_val, COUNT(DISTINCT CustomerName) names, COUNT(DISTINCT Gender) genders FROM reportingview_123 GROUP BY CustomerID HAVING names > 1 OR genders > 1;

-- Show 20 sample rows for any rule that fails (example for the invoice rule):
-- SELECT OrderID, TaxableAmount, GSTAmount, InvoiceAmount FROM reportingview_123 WHERE ABS(TaxableAmount + GSTAmount - InvoiceAmount) > 1 LIMIT 20;


-- ============================================================
-- STEP 4: ANALYSIS
-- First, see which OrderStatus values you have:
-- SELECT OrderStatus, COUNT(*) FROM reportingview_123 GROUP BY OrderStatus;
-- Then edit the list below so that v_sales holds only real sales.
-- ============================================================

CREATE OR REPLACE VIEW v_sales AS
SELECT * FROM reportingview_123
WHERE OrderStatus NOT IN ('Cancelled','Returned');

-- ===== A1: Headline KPIs =====
SELECT COUNT(DISTINCT OrderID) orders, SUM(Quantity) units, ROUND(SUM(InvoiceAmount),0) revenue,
       ROUND(SUM(InvoiceAmount)/COUNT(DISTINCT OrderID),0) avg_order_value,
       ROUND(SUM(DiscountAmount),0) total_discount
FROM v_sales;

-- ===== A2: Revenue by Financial Year and Quarter =====
SELECT FinancialYear, Quarter, COUNT(DISTINCT OrderID) orders, SUM(Quantity) units, ROUND(SUM(InvoiceAmount),0) revenue
FROM v_sales GROUP BY FinancialYear, Quarter ORDER BY FinancialYear, Quarter;

-- ===== A3: Revenue by month =====
SELECT DATE_FORMAT(OrderDate,'%Y-%m') ym, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue
FROM v_sales GROUP BY ym ORDER BY ym;

-- ===== A4: Brand, Series and Model =====
SELECT Brand, COUNT(DISTINCT OrderID) orders, SUM(Quantity) units, ROUND(SUM(InvoiceAmount),0) revenue,
       ROUND(100*SUM(InvoiceAmount)/(SELECT SUM(InvoiceAmount) FROM v_sales),1) revenue_pct
FROM v_sales GROUP BY Brand ORDER BY revenue DESC;

SELECT Brand, Series, SUM(Quantity) units, ROUND(SUM(InvoiceAmount),0) revenue
FROM v_sales GROUP BY Brand, Series ORDER BY revenue DESC LIMIT 15;

SELECT Brand, ModelName, SUM(Quantity) units, ROUND(SUM(InvoiceAmount),0) revenue
FROM v_sales GROUP BY Brand, ModelName ORDER BY revenue DESC LIMIT 15;

-- ===== A5: Geography =====
SELECT Region, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue FROM v_sales GROUP BY Region ORDER BY revenue DESC;
SELECT StoreState, ROUND(SUM(InvoiceAmount),0) revenue FROM v_sales GROUP BY StoreState ORDER BY revenue DESC;
SELECT StoreCity, ROUND(SUM(InvoiceAmount),0) revenue FROM v_sales GROUP BY StoreCity ORDER BY revenue DESC LIMIT 15;
SELECT StoreName, StoreCity, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue FROM v_sales GROUP BY StoreName, StoreCity ORDER BY revenue DESC LIMIT 15;

-- ===== A6: Channel, payment and EMI =====
SELECT ChannelType, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue,
       ROUND(100*SUM(InvoiceAmount)/(SELECT SUM(InvoiceAmount) FROM v_sales),1) revenue_pct
FROM v_sales GROUP BY ChannelType ORDER BY revenue DESC;

SELECT PaymentMethod, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue,
       ROUND(100*COUNT(DISTINCT OrderID)/(SELECT COUNT(DISTINCT OrderID) FROM v_sales),1) order_pct
FROM v_sales GROUP BY PaymentMethod ORDER BY orders DESC;

SELECT EMITenureMonths, COUNT(DISTINCT OrderID) orders, ROUND(AVG(InvoiceAmount),0) avg_invoice
FROM v_sales WHERE EMITenureMonths > 0 GROUP BY EMITenureMonths ORDER BY EMITenureMonths;

-- ===== A7: Discount impact =====
SELECT CASE WHEN DiscountPercent = 0 THEN '0%'
            WHEN DiscountPercent <= 5 THEN '0-5%'
            WHEN DiscountPercent <= 10 THEN '5-10%'
            WHEN DiscountPercent <= 20 THEN '10-20%'
            ELSE '20%+' END discount_band,
       COUNT(DISTINCT OrderID) orders, SUM(Quantity) units, ROUND(SUM(InvoiceAmount),0) revenue, ROUND(SUM(DiscountAmount),0) discount_given
FROM v_sales GROUP BY discount_band ORDER BY MIN(DiscountPercent);

-- ===== A8: Customers =====
SELECT CustomerSegment, COUNT(DISTINCT CustomerID) customers, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue
FROM v_sales GROUP BY CustomerSegment ORDER BY revenue DESC;

SELECT CASE WHEN Age < 25 THEN '<25' WHEN Age < 35 THEN '25-34' WHEN Age < 45 THEN '35-44' WHEN Age < 55 THEN '45-54' ELSE '55+' END age_group,
       COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue, ROUND(AVG(InvoiceAmount),0) avg_invoice
FROM v_sales GROUP BY age_group ORDER BY MIN(Age);

SELECT Gender, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) revenue FROM v_sales GROUP BY Gender;

-- ===== A9: Order status (uses the full view, not v_sales) =====
SELECT OrderStatus, COUNT(DISTINCT OrderID) orders, ROUND(SUM(InvoiceAmount),0) value,
       ROUND(100*COUNT(DISTINCT OrderID)/(SELECT COUNT(DISTINCT OrderID) FROM reportingview_123),1) order_pct
FROM reportingview_123 GROUP BY OrderStatus ORDER BY orders DESC;

-- ===== A10: Delivery performance =====
SELECT ChannelType, ROUND(AVG(DeliveryDays),1) avg_days, MAX(DeliveryDays) max_days,
       ROUND(100*SUM(DeliveryDays > 7)/COUNT(*),1) pct_over_7_days
FROM v_sales GROUP BY ChannelType;

SELECT Region, ROUND(AVG(DeliveryDays),1) avg_days FROM v_sales GROUP BY Region ORDER BY avg_days DESC;
-- ===============================================================================================================================
-- ===============================================================================================================================
-- DATA QUALITY STANDARD DEVIATION
-- sTANDARD DEVIATION
SELECT
    AVG(age)        AS mean_age,
    VARIANCE(age)   AS variance_age,
    STDDEV(age)     AS std_dev_age
FROM customer;

-- SAMPLE VS POP DEV
SELECT
    VAR_SAMP(age)     AS sample_variance,    -- uses n-1
    STDDEV_SAMP(age)  AS sample_std_dev,     -- uses n-1
    VAR_POP(age)      AS population_variance, -- uses n
    STDDEV_POP(age)   AS population_std_dev   -- uses n
FROM customer;

-- SD WHEN NULL
SELECT
    COUNT(age)       AS total_records,
    AVG(age)         AS mean_age,
    STDDEV_SAMP(age) AS std_dev_age
FROM customer
WHERE age IS NOT NULL;

-- FIND Z_SCORE 
-- FOR OUTLIERS CHECK
SELECT customerid, age,
       (age - avg_age) / sd_age AS z_score
FROM CUSTOMER,
     (SELECT AVG(age) AS avg_age,
             STDDEV_SAMP(age) AS sd_age
      FROM CUSTOMER) AS stats
WHERE ABS((age - avg_age) / sd_age) > 3  ;


SELECT STORECity,
       COUNT(age)       AS customers,
       AVG(age)         AS mean_age,
       STDDEV_SAMP(age) AS std_dev_age
FROM REPORTINGVIEW_123
GROUP BY STOREciTY
ORDER BY CUSTOMERS DESC
LIMIT 5;

SELECT COUNT(STORECITY) FROM STOR;

-- ########### PERCENTILE & QUARTILE

-- Situation 3: Outlier detection with IQR

-- This is the method behind the box plot. Flag values beyond Q1 − 1.5×IQR or Q3 + 1.5×IQR.
-- When: data is skewed (income, sales, prices), where the z-score method works poorly.
-- Divide every customer into a quartile group:

-- sql
SELECT customerid, age,
       NTILE(4) OVER (ORDER BY age) AS quartile_group
FROM customer;

-- Percentile rank of each row:

-- sql
SELECT customerid, age,
       ROUND(PERCENT_RANK() OVER (ORDER BY age) * 100, 1) AS percentile_rank
FROM customer;

-- Find outliers using IQR:
use freelancing;
-- sql
WITH ranked AS (SELECT age,
           ROW_NUMBER() OVER (ORDER BY age) AS rn,
           COUNT(*) OVER () AS n
    FROM customer
    WHERE age IS NOT NULL
),q AS (    SELECT
        MAX(CASE WHEN rn = CEIL(0.25 * n) THEN age END) AS q1,
        MAX(CASE WHEN rn = CEIL(0.75 * n) THEN age END) AS q3
    FROM ranked
)SELECT c.customerid, c.age
FROM customer c, q
WHERE c.age < q.q1 - 1.5 * (q.q3 - q.q1)
   OR c.age > q.q3 + 1.5 * (q.q3 - q.q1);
   
   -- (WITH and window functions need MySQL 8 or above.)

-- Excel:

-- =QUARTILE.INC(A1:A100, 1) for Q1
-- =PERCENTILE.INC(A1:A100, 0.9) for P90
-- =MEDIAN(A1:A100)

-- Python:

-- python
-- import pandas as pd
-- df["age"].quantile([0.25, 0.5, 0.75, 0.9])

