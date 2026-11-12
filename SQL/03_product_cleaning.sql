DROP TABLE productdata;
-- CREATED NEW COPY OF DATA NOT RUNNED OR UPDATED YET 
CREATE TABLE  productdata AS
SELECT SRC_ID,
    ProductID, Brand, Series, ModelName, ModelCode, ProcessorBrand, ProcessorModel, 
    RAM_GB, StorageType, StorageCapacity_GB, GraphicsCard, ScreenSize_inch,operatingsystem,
    Color, LaunchYear, ProductCategory, MRP FROM RELIANCE;
 describe main;
 -- RUNNING
SELECT 
    ProductID, Brand, Series, ModelName, ModelCode, ProcessorBrand, ProcessorModel, 
    RAM_GB, StorageType, StorageCapacity_GB, GraphicsCard, ScreenSize_inch,operatingsystem,
    Color, LaunchYear, ProductCategory, MRP FROM productdata order by productid desc ;
  
  SELECT 
    series,productid, processorbrand, modelcode, ram_gb, brand, 
    modelname, StorageCapacity_GB, OperatingSystem,
    COUNT(DISTINCT processormodel) AS processor_count
FROM productdata
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 ,9
HAVING COUNT(DISTINCT processormodel) > 1;

SELECT 
    series,productid, processorbrand, modelcode, ram_gb, brand, 
    modelname, StorageCapacity_GB, OperatingSystem , processormodel
FROM productdata
where productid = 'PRD-20064' ;

SELECT 
    productid, brand, modelname, processormodel AS original_processor,
    CONCAT(
        CASE 
            WHEN modelname LIKE '%Ultra%' THEN 'Intel Core Ultra '
            WHEN processorbrand = 'Intel' THEN 'Intel Core '
            WHEN processorbrand = 'AMD' THEN 
                CONCAT('AMD Ryzen ', SUBSTRING(SUBSTRING_INDEX(SUBSTRING_INDEX(modelname, '(', -1), '/', 1), 1, 1), ' ')
            ELSE ''
        END,
        SUBSTRING_INDEX(SUBSTRING_INDEX(modelname, '(', -1), '/', 1)
    ) AS formatted_derived_processor
FROM productdata;

  -- 

 /*1. Find Product IDs with conflicting details
 LIKE DUPLICATES OR SAME SERIES BRAND BUT DIFFERENT MODELS AND 2 RAM VARIATIONS*/
 SELECT 
    productid,
    COUNT(DISTINCT series) AS unique_series_count,
    COUNT(DISTINCT processorbrand) AS unique_brand_count,
    COUNT(DISTINCT processormodel) AS unique_model_count,
    COUNT(DISTINCT ram_gb) AS unique_ram_count
FROM productdata
GROUP BY productid
HAVING unique_model_count > 1 
    OR unique_brand_count > 1 
    OR unique_series_count > 1
ORDER BY unique_model_count DESC;
-- SAME QUERY
/*******************************************************************************
PURPOSE: Identifies data quality issues where a single 'productid' is incorrectly 
         mapped to multiple different series, processor brands, or processor models.
         
OUTPUT:  Lists the counts of unique variations AND extracts the actual conflicting 
         names into comma-separated lists for easy debugging.
*******************************************************************************/

SELECT 
    productid,
    COUNT(DISTINCT series) AS unique_series_count,
    GROUP_CONCAT(DISTINCT series ORDER BY series SEPARATOR ', ') AS series_names,
    
    COUNT(DISTINCT processorbrand) AS unique_brand_count,
    GROUP_CONCAT(DISTINCT processorbrand ORDER BY processorbrand SEPARATOR ', ') AS brand_names,
    
    COUNT(DISTINCT processormodel) AS unique_model_count,
    GROUP_CONCAT(DISTINCT processormodel ORDER BY processormodel SEPARATOR ', ') AS model_names,
    
    COUNT(DISTINCT ram_gb) AS unique_ram_count,
    GROUP_CONCAT(DISTINCT ram_gb ORDER BY ram_gb SEPARATOR ', ') AS ram_sizes
FROM productdata
GROUP BY productid
HAVING unique_model_count > 1 
    OR unique_brand_count > 1 
    OR unique_series_count > 1
ORDER BY unique_model_count DESC;


/*Identify the Scrambled Columns LIKE DIFFERENT SERIES , 2 Brands , and  too many different models*/
SELECT 
    series, 
    COUNT(DISTINCT brand) AS brand_variants,
    COUNT(DISTINCT processorbrand) AS cpu_brand_variants,
    COUNT(DISTINCT processormodel) AS cpu_model_variants
FROM productdata
GROUP BY series
ORDER BY cpu_model_variants DESC;

/*checking and matching from main
Run the modelcode Audit*/
SELECT modelcode, COUNT(DISTINCT processormodel) AS unique_cpus
FROM main
GROUP BY modelcode
ORDER BY unique_cpus ASC
LIMIT 50;
-- ========================NOOOOOOOOOOOOOOOOO
/*The Dynamic Cleanup Query
 when it isn't scrambled, we will tell MySQL to look at each modelcode,
 find its most common/valid processor, and delete every row in productdata that doesn't match that exact pairing.*/
/* DELETE FROM productdata 
WHERE (modelcode, processormodel) NOT IN (
    SELECT modelcode, processormodel 
    FROM (
        -- This finds the single most frequent, dominant processor for every single model code
        SELECT modelcode, processormodel
        FROM (
            SELECT modelcode, processormodel, COUNT(*) as cnt,
                   ROW_NUMBER() OVER (PARTITION BY modelcode ORDER BY COUNT(*) DESC) as rn
            FROM main
            WHERE modelcode IS NOT NULL AND processormodel IS NOT NULL
            GROUP BY modelcode, processormodel
        ) t
        WHERE t.rn = 1
    ) as dynamic_source_of_truth
);
SELECT *  FROM PRODUCTDATA;

/* Clean the productid AnomaliesThis query finds the single most frequent,
 dominant productid for each unique modelcode configuration and drops all the stray or scrambled IDs from productdata:*/
/*DELETE FROM productdata 
WHERE (modelcode, productid) NOT IN (
    SELECT modelcode, productid 
    FROM (
        SELECT modelcode, productid,
               ROW_NUMBER() OVER (PARTITION BY modelcode ORDER BY COUNT(*) DESC) as rn
        FROM main
        WHERE modelcode IS NOT NULL AND productid IS NOT NULL
        GROUP BY modelcode, productid
    ) t
    WHERE t.rn = 1
);*/
/*Clean the ram_gb Scrambled RowsNext, we align the specs. This query
 automatically determines the true RAM variant that belongs to each specific modelcode and sweeps out the cross-joined 
 garbage records:sql*/
/*DELETE FROM productdata 
WHERE (modelcode, ram_gb) NOT IN (
    SELECT modelcode, ram_gb 
    FROM (
        SELECT modelcode, ram_gb,
               ROW_NUMBER() OVER (PARTITION BY modelcode ORDER BY COUNT(*) DESC) as rn
        FROM main
        WHERE modelcode IS NOT NULL AND ram_gb IS NOT NULL
        GROUP BY modelcode, ram_gb
    ) t
    WHERE t.rn = 1
); */
-- ========================================NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
/*Run the Final Verification*/
SELECT modelcode, 
       COUNT(DISTINCT productid) AS unique_ids, 
       COUNT(DISTINCT processormodel) AS unique_cpus, 
       COUNT(DISTINCT ram_gb) AS unique_rams
FROM productdata
GROUP BY modelcode;
/*Run this verification query to make sure that each productid now maps to a realistic set like eachhave unique ram*/
SELECT productid, modelcode, processormodel, COUNT(DISTINCT ram_gb) as unique_rams
FROM productdata
GROUP BY productid, modelcode, processormodel;
/*final query check now knowing each one unique laptop series and one unique processor model,
 while still allowing for those legitimate multiple RAM configurations (16GB, 32GB, etc.).*/
SELECT 
    productid,
    COUNT(DISTINCT series) AS unique_series,
    COUNT(DISTINCT processormodel) AS unique_processors,
    GROUP_CONCAT(DISTINCT ram_gb ORDER BY ram_gb ASC SEPARATOR ', ') AS available_rams
FROM productdata
GROUP BY productid;

---------------------------------------------------------------------------------------------------
 /*Clean hidden spaces and carriage returns globallyRun this query to strip out leading spaces, trailing spaces,
 and hidden line breaks (\r) across your entire dataset at once*/
UPDATE productdata 
SET 
    series = TRIM(REPLACE(series, '\r', '')),
    processorbrand = TRIM(REPLACE(processorbrand, '\r', '')),
    modelcode = TRIM(REPLACE(modelcode, '\r', '')),
    processormodel = TRIM(REPLACE(processormodel, '\r', '')),
    ram_gb = TRIM(REPLACE(ram_gb, '\r', '')),
    brand = TRIM(REPLACE(brand, '\r', ''));
SELECT * FROM PRODUCTDATA;
-- 1. Create a temporary table containing only the unique rows
CREATE TABLE temp_dedup AS 
SELECT DISTINCT series, processorbrand, modelcode, processormodel, ram_gb, brand, productid 
FROM productdata;

-- 2. Clear out your working table
TRUNCATE TABLE productdata;

-- 3. Move the perfectly cleaned, unique data back into productdata
INSERT INTO productdata (series, processorbrand, modelcode, processormodel, ram_gb, brand, productid)
SELECT series, processorbrand, modelcode, processormodel, ram_gb, brand, productid 
FROM temp_dedup;

-- 4. Delete the temporary table to free up memory
DROP TABLE temp_dedup;
/* checking distinctness now*/
SELECT productid, COUNT(*) as row_count
FROM (
    SELECT DISTINCT series, processorbrand, modelcode, processormodel, ram_gb, brand, productid 
    FROM productdata
) AS distinct_rows
GROUP BY productid
HAVING count(*) > 1;

SELECT productid, COUNT(*) as row_count
FROM main
GROUP BY productid
HAVING COUNT(*) > 1;

SELECT  ProductID, Brand, Series, ModelName, ModelCode, ProcessorBrand, ProcessorModel, RAM_GB, StorageType, StorageCapacity_GB,
GraphicsCard, ScreenSize_inch, OperatingSystem, Color, LaunchYear, ProductCategory, MRP, Quantity,DiscountPercent,Taxableamount,
GSTamount FROM main;

select distinct series, processorbrand ,modelcode , processormodel ,
  ram_gb ,brand , productid  from productdata   order by productid desc 
 limit 20 , 20 ;
 -- -----------------------------------------------------------------------------------------------------------
 -- ***********************************************************************************************************************
 -- Build a temp table holding the majority ProcessorModel per ProductID
CREATE TABLE temp_majority AS
SELECT ProductID, ProcessorModel
FROM (
    SELECT ProductID, ProcessorModel, COUNT(*) AS cnt,
           ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY COUNT(*) DESC) AS rn
    FROM productdata
    GROUP BY ProductID, ProcessorModel
) t
WHERE rn = 1;

-- Index the temp table for a faster join
ALTER TABLE temp_majority ADD INDEX idx_temp_productid (ProductID);

-- Overwrite every row's ProcessorModel with the majority value for its ProductID
UPDATE productdata p
JOIN temp_majority m ON p.ProductID = m.ProductID
SET p.ProcessorModel = m.ProcessorModel;

-- NOTE: this UPDATE is a duplicate of the one directly above - running it a
-- second time is redundant (safe here, but can be removed)


-- Clean up the temp table now that ProcessorModel is standardized
DROP TABLE temp_majority;


select * from productdata;

-- Spot-check GraphicsCard for one specific product
select  productid , GraphicsCard from productdata where productid = "PRD-20338";

-- Count how many rows are missing a GraphicsCard value
select count(*) from productdata where GraphicsCard is null;


-- Find ProductIDs with inconsistent GraphicsCard values
SELECT 
    ProductID, 
    COUNT(DISTINCT GraphicsCard) AS distinct_graphicscard_count,
    COUNT(*) AS total_rows
FROM productdata
GROUP BY ProductID
ORDER BY distinct_graphicscard_count DESC;

-- Look at the actual GraphicsCard values for ProductIDs that have at least one NULL
SELECT ProductID, GraphicsCard, COUNT(*) AS cnt
FROM productdata
WHERE ProductID IN (
    SELECT DISTINCT ProductID FROM productdata WHERE GraphicsCard IS NULL
)
GROUP BY ProductID, GraphicsCard
ORDER BY ProductID, cnt DESC;


-- Fill NULL GraphicsCard values using the majority (most common) non-null
-- GraphicsCard value seen for that same ProductID
UPDATE productdata p
JOIN (
    SELECT ProductID, GraphicsCard
    FROM (
        SELECT ProductID, GraphicsCard, COUNT(*) AS cnt,
               ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY COUNT(*) DESC) AS rn
        FROM productdata
        WHERE GraphicsCard IS NOT NULL
        GROUP BY ProductID, GraphicsCard
    ) t
    WHERE rn = 1
) majority ON p.ProductID = majority.ProductID
SET p.GraphicsCard = majority.GraphicsCard
WHERE p.GraphicsCard IS NULL;


-- Re-check: should now show far fewer (ideally zero) remaining NULLs
SELECT ProductID, GraphicsCard, COUNT(*) AS cnt
FROM productdata
WHERE ProductID IN (
    SELECT DISTINCT ProductID FROM productdata WHERE GraphicsCard IS NULL
)
GROUP BY ProductID, GraphicsCard
ORDER BY ProductID, cnt DESC;


-- Find ProductIDs where OperatingSystem is inconsistent across rows
SELECT 
    ProductID, 
    COUNT(DISTINCT OperatingSystem) AS distinct_os_count,
    COUNT(*) AS total_rows
FROM productdata
GROUP BY ProductID
HAVING COUNT(DISTINCT OperatingSystem) > 1
ORDER BY distinct_os_count DESC;

-- Same check but for ALL ProductIDs (no HAVING filter), for a full picture
SELECT 
    ProductID, 
    COUNT(DISTINCT OperatingSystem) AS distinct_os_count,
    COUNT(*) AS total_rows
FROM productdata
GROUP BY ProductID
ORDER BY distinct_os_count DESC;


-- Find ProductIDs missing a ProductCategory
select productid  from prod where ProductCategory is null;

select * from prod;

-- Find ProductID + ProductCategory combos where MRP is inconsistent
SELECT 
    ProductID, 
    ProductCategory,
    COUNT(DISTINCT MRP) AS distinct_mrp_count,
    COUNT(*) AS total_rows
FROM productdata
GROUP BY ProductID, ProductCategory
HAVING COUNT(DISTINCT MRP) > 1
ORDER BY distinct_mrp_count DESC;


-- ScreenSize_inch = 55 looks like a bad/placeholder value - blank it out to NULL
-- so it can be re-filled with a proper majority value below
UPDATE productdata
SET ScreenSize_inch = NULL
WHERE ScreenSize_inch = 55;

-- Confirm the 55 value is gone from the distinct list
SELECT DISTINCT ScreenSize_inch
FROM productdata
ORDER BY ScreenSize_inch;


-- Find ProductIDs with inconsistent ScreenSize_inch values
SELECT 
    ProductID, 
    COUNT(DISTINCT ScreenSize_inch) AS distinct_screensize_count,
    COUNT(*) AS total_rows
FROM productdata
GROUP BY ProductID
ORDER BY distinct_screensize_count DESC;

-- Same, filtered to only the ProductIDs that actually have a conflict
SELECT 
    ProductID, 
    COUNT(DISTINCT ScreenSize_inch) AS distinct_screensize_count,
    COUNT(*) AS total_rows
FROM PROD
GROUP BY ProductID
HAVING COUNT(DISTINCT ScreenSize_inch) > 1
ORDER BY distinct_screensize_count DESC;

-- Find ProductIDs with at least one NULL ScreenSize_inch
select productid  from prod where  ScreenSize_inch is null;


-- Spot-check one specific product
select * from prod where productid = "PRD-20035";


-- Find ProductIDs that have only ONE row total AND that row's ScreenSize is NULL
-- (these can't be fixed by majority-fill since there's no other row to borrow from)
SELECT 
    ProductID, 
    MAX(ScreenSize_inch) AS ScreenSize_inch,
    COUNT(*) AS total_rows
FROM productdata
GROUP BY ProductID
HAVING COUNT(*) = 1 
   AND MAX(ScreenSize_inch) IS NULL;
   
-- Look at the actual ScreenSize_inch values for ProductIDs that have at least one NULL
   SELECT ProductID, ScreenSize_inch, COUNT(*) AS cnt
FROM productdata
WHERE ProductID IN (
    SELECT DISTINCT ProductID FROM productdata WHERE ScreenSize_inch IS NULL
)
GROUP BY ProductID, ScreenSize_inch
ORDER BY ProductID, cnt DESC;


-- Fill NULL ScreenSize_inch values using the majority (most common) non-null
-- ScreenSize_inch value seen for that same ProductID
UPDATE productdata p
JOIN (
    SELECT ProductID, ScreenSize_inch
    FROM (
        SELECT ProductID, ScreenSize_inch, COUNT(*) AS cnt,
               ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY COUNT(*) DESC) AS rn
        FROM productdata
        WHERE ScreenSize_inch IS NOT NULL
        GROUP BY ProductID, ScreenSize_inch
    ) t
    WHERE rn = 1
) majority ON p.ProductID = majority.ProductID
SET p.ScreenSize_inch = majority.ScreenSize_inch
WHERE p.ScreenSize_inch IS NULL;



-- ------------------------------------------------------------
-- delete duplicate rows
-- Step 0: Add a temporary unique row identifier (PROD doesn't have one like IDX_NO)
-- ------------------------------------------------------------
ALTER TABLE productdata
 ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;

-- Confirm the new index/primary key was added
SHOW INDEX FROM productdata;


-- Step 1: Find the rows to KEEP (min row_id per ProductID, i.e. earliest record)
CREATE TABLE PROD_KEEP AS
SELECT MIN(row_id) AS keep_id
FROM productdata
GROUP BY ProductID;

-- Step 2: Add index on the temp table so the DELETE's sub-query runs fast
ALTER TABLE PROD_KEEP ADD INDEX idx_keep (keep_id);

-- Step 3: Delete everything NOT in the keep list (removes the duplicate rows)
DELETE FROM productdata
WHERE row_id NOT IN (SELECT keep_id FROM PROD_KEEP);

-- Step 4: Cleanup - drop the temp table now that de-dup is done
DROP TABLE PROD_KEEP;
select * from productdata;

-- Final verification: should return zero rows (no more duplicate ProductIDs)
SELECT ProductID, COUNT(*) AS cnt
FROM productdata
GROUP BY ProductID
HAVING COUNT(*) > 1;


-- Final row count for PROD after cleanup
select count(*) from productdata;
 