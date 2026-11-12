-- CREATED NEW TABLE WITH FORMATTINGS ON 09-09-2026
USE FREELANCING;
DROP TABLE CUSTOMER;
CREATE TABLE CUSTOMER
SELECT  src_id,CustomerID,CustomerName,Gender,Age,
City,State,CustomerSegment FROM reliance;
DESCRIBE MAIN;
USE FREELANCING;
SELECT * FROM CUSTOMER;
SELECT *
FROM CUSTOMER
WHERE AGE IS NULL AND CUSTOMERID IS NOT NULL;
/*COLUMN COUNT NIKALNA*/
select count(*) as 'total column' 
from information_schema.columns 
where table_name ='CUSTOMER' and table_schema ='FREELANCING';

-- CUSTOMER TABLE -- 

-- View the table structure, data types, and column constraints
DESC CUSTOMER;

-- Identify specific CustomerIDs that have duplicate records and count them
SELECT 
CustomerID,
COUNT(*) AS DuplicateCount
FROM CUSTOMER
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- Calculate the total number of redundant/duplicate rows in the table
SELECT COUNT(*) - COUNT(DISTINCT CustomerID) AS Total_Duplicate_Data
FROM CUSTOMER;

-- Delete all records for any CustomerID that has duplicate entries


-- Find customer names containing special characters or punctuation marks
SELECT CUSTOMERNAME AS 'CUSTOMER NAME' FROM CUSTOMER WHERE CUSTOMERNAME REGEXP '[^a-zA-Z0-9 ]';
-- SOLUTION --
-- Strip out special characters from names, leaving only letters and single spaces
UPDATE CUSTOMER
SET CUSTOMERNAME = TRIM(REGEXP_REPLACE(REGEXP_REPLACE(CUSTOMERNAME, '[^a-zA-Z ]', ' '),' +',' '))
WHERE CUSTOMERNAME IS NOT NULL;

-- Clean text fields: trim spaces, collapse multiple spaces, and convert empty strings to NULL
UPDATE CUSTOMER
SET
    CustomerID = NULLIF(REGEXP_REPLACE(TRIM(CustomerID), ' +', ' '), ''),
    CustomerName = NULLIF(REGEXP_REPLACE(TRIM(CustomerName), ' +', ' '), ''),
    Gender = NULLIF(REGEXP_REPLACE(TRIM(Gender), ' +', ' '), ''),
    AGE = NULLIF(REGEXP_REPLACE(TRIM(AGE), ' +', ' '), ''),
    CustomerPhone = NULLIF(REGEXP_REPLACE(TRIM(CustomerPhone), ' +', ' '), ''),
    CustomerEmail = NULLIF(REGEXP_REPLACE(TRIM(CustomerEmail), ' +', ' '), ''),
    CustomerAddress = NULLIF(REGEXP_REPLACE(TRIM(CustomerAddress), ' +', ' '), ''),
    City = NULLIF(REGEXP_REPLACE(TRIM(City), ' +', ' '), ''),
    State = NULLIF(REGEXP_REPLACE(TRIM(State), ' +', ' '), ''),
    PinCode = NULLIF(REGEXP_REPLACE(TRIM(PinCode), ' +', ' '), ''),
    CustomerSegment = NULLIF(REGEXP_REPLACE(TRIM(CustomerSegment), ' +', ' '), '');
    
-- Remove unused or redundant contact and address columns from the table schema
ALTER TABLE CUSTOMER
DROP COLUMN CustomerPhone,
DROP COLUMN CustomerEmail,
DROP COLUMN CustomerAddress,
DROP COLUMN PinCode;

-- Standardize gender values into uniform categories ('Men' and 'Women')
UPDATE customer
SET Gender = CASE
    WHEN Gender IN ('MALE', 'M') THEN 'MALE'
    WHEN Gender IN ('FEMALE', 'F') THEN 'FEMALE'
    ELSE Gender
END;

-- Strip out special characters from city names, leaving only letters and single spaces
UPDATE CUSTOMER
SET City = TRIM(REGEXP_REPLACE(REGEXP_REPLACE(City, '[^a-zA-Z ]', ' '),' +',' '))
WHERE City IS NOT NULL;


-- Strip out special characters from state names, leaving only letters and single spaces
UPDATE CUSTOMER
SET State = TRIM(REGEXP_REPLACE(REGEXP_REPLACE(State, '[^a-zA-Z ]', ' '),' +',' '))
WHERE State IS NOT NULL;

-- Convert City and State names to standard Title Case format (e.g., 'New York')
UPDATE CUSTOMER
SET 
    City = CONCAT(UPPER(LEFT(City, 1)), LOWER(MID(City, 2))),
    State = CONCAT(UPPER(LEFT(State, 1)), LOWER(MID(State, 2)))
WHERE City IS NOT NULL AND State IS NOT NULL;

SELECT * FROM CUSTOMER;

-- check segment problems
SELECT 
    CUSTOMERSEGMENT ,
    CASE
        WHEN CUSTOMERSEGMENT IN ('NEW', 'NEW CUSTOMRE') THEN 'NEW CUSTOMER'
        WHEN CUSTOMERSEGMENT IN ('REPEAT', 'RETURNING') THEN 'REPEAT'
        WHEN CUSTOMERSEGMENT IN ('PREMIUM', 'RELIANCE ONE MEMBER') THEN 'PREMIUM'
        ELSE CUSTOMERSEGMENT 
    END
FROM CUSTOMER;
-- UPDATE CUSTOMER SEGMENT
UPDATE CUSTOMER
SET  CUSTOMERSEGMENT = CASE
        WHEN CUSTOMERSEGMENT IN ('NEW', 'NEW CUSTOMRE') THEN 'NEW CUSTOMER'
        WHEN CUSTOMERSEGMENT IN ('REPEAT', 'RETURNING') THEN 'REPEAT'
        WHEN CUSTOMERSEGMENT IN ('PREMIUM', 'RELIANCE ONE MEMBER') THEN 'PREMIUM'
        ELSE CUSTOMERSEGMENT 
END; 
 -- Retrieve all rows and columns to review the current state of the data   
SELECT * FROM CUSTOMER;
-- Find the most frequent age value (Mode) appearing in the dataset
SELECT AGE, COUNT(*) AS CNT
FROM CUSTOMER
WHERE AGE IS NOT NULL
GROUP BY AGE
ORDER BY CNT DESC
LIMIT 1;    
-- 10-09-2026
-- =====================================================================
-- SECTION 1: AGE COLUMN OPERATIONS
-- =====================================================================

-- Inspect age data before modifying data type
SELECT age FROM CUSTOMER;

-- Update the data type of the Age column to Integer
ALTER TABLE CUSTOMER
MODIFY COLUMN Age INT;

-- Inspect specific boundary records before setting extreme ages to NULL
SELECT age FROM CUSTOMER WHERE age = 71;

-- Clean extreme age values: Set age to NULL for entries under 15 and over 70
-- Note: Fixed logic constraint to correctly catch under 15 OR over 70
UPDATE CUSTOMER
SET age = NULL 
WHERE age <= 15 OR age > 70;

CREATE TEMPORARY TABLE TEMP_age AS
SELECT
    CustomerID,
    age,
    COUNT(*) AS CNT
FROM CUSTOMER
WHERE age IS NOT NULL
GROUP BY CustomerID, age;

ALTER TABLE TEMP_age
ADD INDEX idx_customer (CustomerID);

UPDATE CUSTOMER t
JOIN TEMP_age m
    ON t.CustomerID = m.CustomerID
SET
 t.age = m.age;
DROP TABLE TEMP_age;


-- Fill missing age values with the global average age of existing customers
UPDATE CUSTOMER 
SET age = (SELECT avg_age FROM (SELECT AVG(age) AS avg_age FROM CUSTOMER) AS temp) 
WHERE age IS NULL;

-- =====================================================================
-- SECTION 2: GEOGRAPHY (CITY & STATE) INSPECTION & DATA CLEANING
-- =====================================================================

-- 1. Inspect geographical distributions: Group cities under their respective states
SELECT State, GROUP_CONCAT(DISTINCT City ORDER BY City SEPARATOR ', ') AS Cities
FROM CUSTOMER
GROUP BY State
ORDER BY State;

-- 2. Inspect invalid strings: Find cities/states containing numbers, punctuation, or special characters
SELECT City, State 
FROM CUSTOMER 
WHERE City REGEXP '[^a-zA-Z ]' OR State REGEXP '[^a-zA-Z ]';

-- 3. Inspect formatting anomalies: Find empty strings, space-only entries, or strings shorter than 2 characters
SELECT City, State, LENGTH(City) AS CityLen, LENGTH(State) AS StateLen
FROM MAIN
WHERE TRIM(City) = '' OR TRIM(State) = '' OR LENGTH(City) < 2 OR LENGTH(State) < 2;

-- 4. Inspect specific anomaly: Look for missing or corrupted city data for a specific Tamil Nadu record
SELECT CUSTOMERID, CITY , STATE
FROM CUS
WHERE CUSTOMERID = 'RD-CUST-145864' ;

-- 5. Inspect data frequency: Group and count frequencies to spot typos, spelling variations, or trailing spaces
SELECT City, State, COUNT(*) AS RecordCount
FROM CUSTOMER
GROUP BY City, State
ORDER BY City ASC, RecordCount DESC;

-- 6. Inspect mismatched pairs: Identify records where a City is mapped to an incorrect/minority State
SELECT c.City, c.State AS Current_State, s.Correct_State
FROM CUSTOMER c
JOIN (
    SELECT City, State AS Correct_State
    FROM MAIN
    GROUP BY City, State
    ORDER BY COUNT(*) DESC
) s ON c.City = s.City
WHERE c.State <> s.Correct_State;

-- orrr
-- 7. Execute Fix: Standardise state assignments using the most frequently occurring State-City mapping (High-Performance Method)
UPDATE CUSTOMER c
JOIN (
    SELECT City, State AS Correct_State
    FROM (
        SELECT City, State, 
               ROW_NUMBER() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) as rn
        FROM CUSTOMER
        WHERE City IS NOT NULL AND State IS NOT NULL
        GROUP BY City, State
    ) t
    WHERE rn = 1
) s ON c.City = s.City
SET c.State = s.Correct_State
WHERE c.State <> s.Correct_State;
-- OR WITHOUT WINDOW FUNCTION SLOWER VERSION
UPDATE CUSTOMER c
JOIN (
    SELECT City, State AS Correct_State
    FROM CUSTOMER
    GROUP BY City, State
    HAVING (City, COUNT(*)) IN (
        SELECT City, MAX(cnt) 
        FROM (SELECT City, State, COUNT(*) as cnt FROM CUSTOMER GROUP BY City, State) tmp 
        GROUP BY City
    )
) s ON c.City = s.City
SET c.State = s.Correct_State
WHERE c.State <> s.Correct_State;
-- Check existing state values
SELECT DISTINCT(State) FROM CUSTOMER;

-- Standardize state names
UPDATE CUSTOMER
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

-- Check standardized state values
SELECT DISTINCT(State) FROM CUSTOMER;

-- Clean decimal values from Age
UPDATE CUSTOMER
SET Age = ROUND(Age)
WHERE Age LIKE '%.%';

-- Add AgeGroup column
ALTER TABLE CUSTOMER
ADD COLUMN AgeGroup VARCHAR(50) AFTER Age;

-- Create AgeGroup based on Age
UPDATE CUSTOMER
SET AgeGroup =
CASE
    WHEN Age BETWEEN 15 AND 35 THEN 'Young Adult'
    WHEN Age BETWEEN 36 AND 59 THEN 'Adult'
    WHEN Age >= 60 THEN 'Senior'
END;

-- Check AgeGroup values
SELECT DISTINCT(AgeGroup) FROM CUSTOMER;

-- =====================================================================
-- SECTION 3: SYSTEM INSPECTION & DUPLICATE REMOVAL (NEW TABLE STAGING)
-- =====================================================================

-- Check system layout schema
DESCRIBE MAIN;

/* -- Clone data into a new backup staging table
CREATE TABLE cus AS
SELECT * FROM CUSTOMER;

-- Add a sequential serial number primary key to the new table
ALTER TABLE CUSTOMER ADD COLUMN CID INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- --- - Delete duplicate records from the new staging table, keeping only the first instance per
-- -- -- CustomerID BUT BECAUSE OF JOIN IT IS NOT WORKING IN MINUTES
-- -- -- DELETE c1 FROM cus c1
-- -- -- INNER JOIN cus c2 
-- -- -- WHERE c1.Sl_No > c2.Sl_No 
-- -- --   AND c1.CustomerID = c2.CustomerID;
-- -- -- SELECT COUNT(*) FROM CUS;
-- -- -- DROP TABLE cus;
*/
CREATE TEMPORARY TABLE TEMP_CITY AS
SELECT
    CustomerID,
    CITY,
    COUNT(*) AS CNT
FROM CUSTOMER
WHERE CITY IS NOT NULL
GROUP BY CustomerID, CITY;

ALTER TABLE TEMP_CITY
ADD INDEX idx_customer (CustomerID);

SELECT * FROM CUSTOMER WHERE CITY IS NULL;
 
SELECT CUSTOMERID,CITY , COUNT(*) AS CNT
FROM CUSTOMER WHERE CITY IS NULL
GROUP BY CUSTOMERID,CITY;

UPDATE CUSTOMER t
JOIN TEMP_CITY m
    ON t.CustomerID = m.CustomerID
SET
    t.CITY = m.CITY
WHERE t.CITY IS NULL;
DROP TABLE TEMP_CITY;
SELECT DISTINCT(CUSTOMERID) FROM CUSTOMER WHERE AGE IS NULL;
-- 1194 - 1151 = 43

SELECT CustomerID, COUNT(*) AS Total_Rows, SUM(Age IS NULL) AS Null_Age_Count
FROM CUSTOMER
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1 AND SUM(Age IS NULL) > 1
ORDER BY Null_Age_Count DESC;
-- 42

SELECT * FROM CUSTOMER WHERE CUSTOMERID = 'RD-CUST-118625';

UPDATE customeR SET CITY = 'Not Available' where city is null; 
select * from cOPYDATA WHERE CUSTOMERID = 'RD-CUST-149618';
select * from cUSTOMER WHERE CUSTOMERID = 'RD-CUST-163176';

SELECT
    CustomerID,
    COUNT(*) AS Total_Rows
FROM CUSTOMER
GROUP BY CustomerID;

SELECT COUNT(DISTINCT CUSTOMERID) FROM CUSTOMER;

CREATE TEMPORARY TABLE TEMP_STATE AS
SELECT
    CustomerID,
    STATE,
    COUNT(*) AS CNT
FROM CUSTOMER
WHERE STATE IS NOT NULL
GROUP BY CustomerID, STATE;

ALTER TABLE TEMP_STATE
ADD INDEX idx_customer (CustomerID);

UPDATE CUSTOMER t
JOIN TEMP_STATE m
    ON t.CustomerID = m.CustomerID
SET
 t.STATE = m.STATE;
DROP TABLE TEMP_STATE;

-- Add sequential primary key
ALTER TABLE CUSTOMER
ADD COLUMN ID INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- Delete duplicate customers and keep the first CID
DELETE FROM CUSTOMER
WHERE ID NOT IN (
    SELECT MIN(ID)FROM (SELECT ID, CustomerID FROM CUSTOMER) AS X GROUP BY CustomerID
    );
    
    select count(*) from CUSTOMER;
