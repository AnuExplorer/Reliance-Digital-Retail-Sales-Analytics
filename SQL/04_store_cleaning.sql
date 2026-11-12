/* =====================================================================
   STORE TABLE CLEANING SCRIPT
   Database : FREELANCING
   Source   : RELIANCE (raw table, never modified)
   Output   : STOR (one clean row per StoreID)

   LEGEND
   [RUN]      = needed for the cleaning, executes normally
   [OPTIONAL] = look-up / preview / validation query. Commented out so the
                script runs cleanly end to end. Un-comment to inspect data.
   [NOTE]     = something worth knowing (change made, caution)

   RUN ORDER: top to bottom, in one pass.
   Cleaning order matters: text cleaning -> fix State -> fill missing
   StoreName -> remove duplicates. Duplicates are removed LAST so the row
   that is kept already has the corrected values.
   ===================================================================== */


/* =====================================================================
   STEP 1: SETUP
   ===================================================================== */

-- [RUN] PURPOSE: Select the working database.
-- RESULT : All following statements run against FREELANCING.
USE FREELANCING;

-- [RUN] PURPOSE: Remove any earlier version of the store table so the script
--                can be re-run from the top.
-- RESULT : STOR is dropped if it exists (no error if it does not).
-- [NOTE] Original was "DROP TABLE STOR;", which errors when the table is missing.
DROP TABLE IF EXISTS STOR;

-- [OPTIONAL] PURPOSE: View the whole raw data.
-- RESULT : Every row and column of RELIANCE (large output, not needed for cleaning).
-- SELECT * FROM RELIANCE;

-- [RUN] PURPOSE: Build the store table from the store-related columns only.
--                SRC_ID is kept as the unique row key for de-duplication later.
-- RESULT : New table STOR (6 columns), one row per source row of RELIANCE,
--          so StoreIDs repeat many times at this stage.
CREATE TABLE STOR
SELECT
    SRC_ID,
    StoreID,
    StoreName,
    StoreCity,
    StoreState,
    Region
FROM RELIANCE;

-- [OPTIONAL] PURPOSE: Count the columns of STOR (should be 6).
-- RESULT : One number in column 'total column'.
-- SELECT COUNT(*) AS 'total column'
-- FROM information_schema.columns
-- WHERE table_name = 'STOR' AND table_schema = 'FREELANCING';

-- [OPTIONAL] PURPOSE: Check the structure (data types) of STOR.
-- RESULT : Column names, types, nulls.
-- DESC STOR;


/* =====================================================================
   STEP 2: MEASURE THE DUPLICATE PROBLEM (look-ups only)
   ===================================================================== */

-- [OPTIONAL] PURPOSE: Total rows in STOR before de-duplication.
-- RESULT : One number = TOTAL_RECORDS.
-- [NOTE] Original alias was misspelt "TOTAK_RECORD".
-- SELECT COUNT(*) AS TOTAL_RECORDS FROM STOR;

-- [OPTIONAL] PURPOSE: Number of unique stores (= rows expected after de-duplication).
-- RESULT : One number = UNIQUE_STORES.
-- SELECT COUNT(DISTINCT StoreID) AS UNIQUE_STORES FROM STOR;

-- [OPTIONAL] PURPOSE: How many extra (duplicate) rows exist.
-- RESULT : Total rows minus unique StoreIDs.
-- [NOTE] Run again after Step 3. Before text cleaning, ID values that differ only
--        by spaces count as different stores, so the number can be too high.
-- SELECT COUNT(*) - COUNT(DISTINCT StoreID) AS Total_Duplicate_Data FROM STOR;


/* =====================================================================
   STEP 3: TEXT CLEANING
   ===================================================================== */

-- [RUN] PURPOSE: Standardise every column:
--          TRIM                        -> remove leading/trailing spaces
--          REGEXP_REPLACE(' +', ' ')   -> collapse repeated spaces into one
--          UPPER (StoreID only)        -> same casing as ORDER_I.StoreID
--          NULLIF(x, '')               -> convert empty strings to real NULLs
-- RESULT : Blank values become NULL, spacing is uniform, so later grouping
--          and joins treat identical stores as identical.
-- [NOTE] UPPER on StoreID is an addition: the order script upper-cases StoreID,
--        so STOR must match it or joins on StoreID can miss rows. Name, city,
--        state and region keep their original casing.
UPDATE STOR
SET
    StoreID    = NULLIF(UPPER(REGEXP_REPLACE(TRIM(StoreID), ' +', ' ')), ''),
    StoreName  = NULLIF(REGEXP_REPLACE(TRIM(StoreName), ' +', ' '), ''),
    StoreCity  = NULLIF(REGEXP_REPLACE(TRIM(StoreCity), ' +', ' '), ''),
    StoreState = NULLIF(REGEXP_REPLACE(TRIM(StoreState), ' +', ' '), ''),
    Region     = NULLIF(REGEXP_REPLACE(TRIM(Region), ' +', ' '), '');


/* =====================================================================
   STEP 4: INVESTIGATE DUPLICATES (look-ups only)
   Goal: find out whether repeated StoreIDs are true copies or carry
   conflicting information.
   ===================================================================== */

-- [OPTIONAL] PURPOSE: Classify repeated StoreIDs into two groups:
--                     exact copies vs. same ID with different details.
-- RESULT : Two-row summary: duplicate_type, number_of_storeIDs, total_rows_involved.
-- SELECT
--     CASE
--         WHEN distinct_versions = 1 THEN 'Exact Duplicate (All Columns Same)'
--         ELSE 'Different Data (Same StoreID, Different Info)'
--     END AS duplicate_type,
--     COUNT(*)        AS number_of_storeIDs,    -- StoreIDs in this bucket
--     SUM(total_rows) AS total_rows_involved    -- rows across those StoreIDs
-- FROM (
--     SELECT
--         StoreID,
--         COUNT(*) AS total_rows,
--         -- Joining the identity columns lets us count how many different
--         -- "versions" of a store exist under one StoreID
--         COUNT(DISTINCT CONCAT_WS('|', StoreName, StoreCity, StoreState, Region)) AS distinct_versions
--     FROM STOR
--     GROUP BY StoreID
--     HAVING COUNT(*) > 1                       -- only IDs that repeat
-- ) AS duplicate_summary
-- GROUP BY duplicate_type;

-- [OPTIONAL] PURPOSE: List ALL rows of every repeated StoreID so the differences
--                     can be seen side by side.
-- RESULT : All duplicate rows, ordered by StoreID.
-- SELECT s.*
-- FROM STOR s
-- INNER JOIN (
--     SELECT StoreID FROM STOR GROUP BY StoreID HAVING COUNT(*) > 1
-- ) dup ON s.StoreID = dup.StoreID
-- ORDER BY s.StoreID;

-- [OPTIONAL] PURPOSE: Find StoreIDs that have conflicting name, state or city.
-- RESULT : Only StoreIDs with more than one distinct name/state/city.
-- [NOTE] Original alias "storename" for the name count is renamed distinct_names.
-- SELECT
--     StoreID,
--     COUNT(DISTINCT StoreName)  AS distinct_names,
--     COUNT(DISTINCT StoreState) AS distinct_states,
--     COUNT(DISTINCT StoreCity)  AS distinct_cities,
--     COUNT(*)                   AS total_rows
-- FROM STOR
-- GROUP BY StoreID
-- HAVING COUNT(DISTINCT StoreName) > 1
--     OR COUNT(DISTINCT StoreState) > 1
--     OR COUNT(DISTINCT StoreCity) > 1
-- ORDER BY StoreID;

-- [OPTIONAL] PURPOSE: Inspect one conflicting store (RD-STR-1030): every
--                     state + city combination and how often it appears.
-- RESULT : Combinations sorted by frequency.
-- SELECT StoreID, StoreState, StoreCity, COUNT(*) AS combo_count
-- FROM STOR
-- WHERE StoreID = 'RD-STR-1030'
-- GROUP BY StoreID, StoreState, StoreCity
-- ORDER BY combo_count DESC;

-- [OPTIONAL] PURPOSE: Same store, state-wise count only.
-- RESULT : Each state with its row count (the most frequent one is the likely truth).
-- SELECT StoreID, StoreState, COUNT(*) AS state_count
-- FROM STOR
-- WHERE StoreID = 'RD-STR-1030'
-- GROUP BY StoreID, StoreState
-- ORDER BY state_count DESC;

-- [OPTIONAL] PURPOSE: Same store, city-wise count only.
-- RESULT : Each city with its row count.
-- SELECT StoreID, StoreCity, COUNT(*) AS city_count
-- FROM STOR
-- WHERE StoreID = 'RD-STR-1030'
-- GROUP BY StoreID, StoreCity
-- ORDER BY city_count DESC;


/* =====================================================================
   STEP 5: FIX CONFLICTING STORESTATE (majority value wins)
   ===================================================================== */

-- [OPTIONAL] PURPOSE: Preview the state that will be chosen for every store:
--                     the most frequent state under that StoreID.
-- RESULT : One row per StoreID: StoreID, winning StoreState, its count.
-- SELECT StoreID, StoreState, state_count
-- FROM (
--     SELECT
--         StoreID, StoreState,
--         COUNT(*) AS state_count,
--         ROW_NUMBER() OVER (PARTITION BY StoreID
--                            ORDER BY COUNT(*) DESC, StoreState) AS rn
--     FROM STOR
--     WHERE StoreState IS NOT NULL
--     GROUP BY StoreID, StoreState
-- ) ranked
-- WHERE rn = 1
-- ORDER BY StoreID;

-- [RUN] PURPOSE: Overwrite StoreState in every row with the most frequent state
--                of that StoreID, so all rows of a store agree.
-- RESULT : Each StoreID has exactly one StoreState across all its rows.
-- [NOTE] Two safety changes to the original:
--        1. WHERE StoreState IS NOT NULL - a NULL can no longer win the vote
--           and wipe out real states.
--        2. ORDER BY COUNT(*) DESC, StoreState - ties are now broken the same
--           way every run (alphabetically) instead of randomly.
UPDATE STOR s
JOIN (
    SELECT StoreID, StoreState
    FROM (
        SELECT
            StoreID, StoreState,
            COUNT(*) AS state_count,
            ROW_NUMBER() OVER (PARTITION BY StoreID
                               ORDER BY COUNT(*) DESC, StoreState) AS rn
        FROM STOR
        WHERE StoreState IS NOT NULL
        GROUP BY StoreID, StoreState
    ) ranked
    WHERE rn = 1
) best ON s.StoreID = best.StoreID
SET s.StoreState = best.StoreState;
-- [NOTE] Only StoreState is repaired. StoreCity conflicts (Step 4 look-ups) are
--        not fixed; if the checks show city conflicts, apply the same
--        majority-vote UPDATE to StoreCity before Step 7.


/* =====================================================================
   STEP 6: FILL MISSING STORENAME
   ===================================================================== */

-- [OPTIONAL] PURPOSE: Count NULLs in every column.
-- RESULT : One row per column with its null_count (run before and after fixes to compare).
-- SELECT 'StoreID' AS column_name, COUNT(*) - COUNT(StoreID) AS null_count FROM STOR
-- UNION ALL SELECT 'StoreName',  COUNT(*) - COUNT(StoreName)  FROM STOR
-- UNION ALL SELECT 'StoreCity',  COUNT(*) - COUNT(StoreCity)  FROM STOR
-- UNION ALL SELECT 'StoreState', COUNT(*) - COUNT(StoreState) FROM STOR
-- UNION ALL SELECT 'Region',     COUNT(*) - COUNT(Region)     FROM STOR;

-- [OPTIONAL] PURPOSE: List the stores that have a missing StoreName.
-- RESULT : StoreIDs of rows where StoreName is NULL.
-- SELECT StoreID FROM STOR WHERE StoreName IS NULL;

-- [OPTIONAL] PURPOSE: Look at one such store (RD-STR-1050) before the fix.
-- RESULT : All rows of RD-STR-1050.
-- SELECT * FROM STOR WHERE StoreID = 'RD-STR-1050';

-- [RUN] PURPOSE: Fill a NULL StoreName from another row of the same StoreID that
--                has a name.
-- RESULT : NULL names are replaced where a valid name exists for that StoreID.
--          Stores whose every row is NULL stay NULL.
-- [NOTE] MAX() simply picks one name; if a store has two different names, it takes
--        the alphabetically last. Fine if names are consistent per store.
UPDATE STOR s
JOIN (
    SELECT StoreID, MAX(StoreName) AS valid_name
    FROM STOR
    WHERE StoreName IS NOT NULL
    GROUP BY StoreID
) t ON s.StoreID = t.StoreID
SET s.StoreName = t.valid_name
WHERE s.StoreName IS NULL;

-- [OPTIONAL] PURPOSE: View the whole table after the fixes.
-- SELECT * FROM STOR;


/* =====================================================================
   STEP 7: REMOVE DUPLICATE STORES
   ===================================================================== */

-- [RUN] PURPOSE: Keep exactly one row per StoreID (the one with the lowest SRC_ID)
--                and delete the rest.
--                The inner query is wrapped in a derived table (STR) because MySQL
--                does not allow selecting from the table being deleted from
--                in the same subquery (error 1093).
-- RESULT : STOR holds one row per StoreID. Because Steps 3, 5 and 6 ran first,
--          the surviving row already has the cleaned values.
DELETE FROM STOR
WHERE SRC_ID NOT IN (
    SELECT MIN(SRC_ID)
    FROM (SELECT SRC_ID, StoreID FROM STOR) AS STR
    GROUP BY StoreID
);

-- [OPTIONAL] PURPOSE: Final look at the sample store RD-STR-1050.
-- RESULT : Exactly one row expected.
-- SELECT * FROM STOR WHERE StoreID = 'RD-STR-1050' ORDER BY SRC_ID;

-- [RUN] PURPOSE: Final validation - rows must equal unique StoreIDs.
-- RESULT : total_rows = unique_stores, so duplicate_rows = 0.
SELECT COUNT(*)                                AS total_rows,
       COUNT(DISTINCT StoreID)                 AS unique_stores,
       COUNT(*) - COUNT(DISTINCT StoreID)      AS duplicate_rows
FROM STOR;