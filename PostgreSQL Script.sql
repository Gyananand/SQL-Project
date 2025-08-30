-- ##########################################
-- # Project: PAN Number Validation
-- ##########################################

-- ==========================================
-- STEP 1: Create Table for PAN Dataset
-- ==========================================
CREATE TABLE stg_pan_num_dataset (
    pan_numbers text
);

-- Check total records
SELECT COUNT(*) AS total_records
FROM stg_pan_num_dataset;


-- ==========================================
-- STEP 2: Data Cleaning and Preprocessing
-- ==========================================

-- 2.1 Identify missing data
SELECT COUNT(*) AS missing_records
FROM stg_pan_num_dataset spnd
WHERE pan_numbers IS NULL OR pan_numbers = '';

-- 2.2 Check for duplicates
SELECT pan_numbers,
       COUNT(1) AS duplicates
FROM stg_pan_num_dataset spnd
GROUP BY pan_numbers
HAVING COUNT(1) > 1;

-- 2.3 Identify leading/trailing spaces
SELECT *
FROM stg_pan_num_dataset spnd
WHERE pan_numbers != TRIM(pan_numbers);

-- 2.4 Check for inconsistent letter case
SELECT COUNT(pan_numbers) AS total_letter_case_issues
FROM stg_pan_num_dataset spnd
WHERE pan_numbers != UPPER(pan_numbers);

-- 2.5 Cleaned PAN numbers
SELECT DISTINCT UPPER(TRIM(pan_numbers)) AS cleaned_pan
FROM stg_pan_num_dataset spnd
WHERE TRIM(pan_numbers) != '';


-- ==========================================
-- STEP 3: Custom Validation Functions
-- ==========================================

-- 3.1 Function to check adjacent duplicate characters
CREATE OR REPLACE FUNCTION fn_check_adjacent_character(p_str text) 
RETURNS text LANGUAGE PLPGSQL AS $$
BEGIN
    FOR i IN 1..(length(p_str) - 1) LOOP
        IF substring(p_str, i, 1) = substring(p_str, i+1, 1) THEN
            RETURN 'Has adjacent duplicates';
        END IF;
    END LOOP;
    RETURN 'No adjacent duplicates';
END;
$$;

-- Example usage
SELECT fn_check_adjacent_character('ABDEF');

-- 3.2 Function to check sequential characters
CREATE OR REPLACE FUNCTION fn_check_sequential_character(p_str text) 
RETURNS text LANGUAGE PLPGSQL AS $$
DECLARE
    is_seq boolean := true;
BEGIN
    FOR i IN 1..(length(p_str) - 1) LOOP
        IF ascii(substring(p_str, i+1, 1)) - ascii(substring(p_str, i, 1)) != 1 THEN
            is_seq := false;
            EXIT;
        END IF;
    END LOOP;

    IF is_seq THEN
        RETURN 'Characters forming sequence';
    ELSE
        RETURN 'Characters not forming sequence';
    END IF;
END;
$$;

-- Example usage
SELECT fn_check_sequential_character('ABCDF');


-- ==========================================
-- STEP 4: Validate PAN Structure with Regex
-- ==========================================
-- Valid format: AAAAA1234A
SELECT *
FROM stg_pan_num_dataset spnd
WHERE pan_numbers ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
LIMIT 10;


-- ==========================================
-- STEP 5: Categorize PANs as Valid/Invalid
-- ==========================================
CREATE OR REPLACE VIEW PAN_status AS
WITH cte_cleaned_pan AS (
    SELECT DISTINCT UPPER(TRIM(pan_numbers)) AS pan_number
    FROM stg_pan_num_dataset spnd
    WHERE TRIM(pan_numbers) != ''
),
cte_valid_pan AS (
    SELECT *
    FROM cte_cleaned_pan cln
    WHERE fn_check_adjacent_character(cln.pan_number) = 'No adjacent duplicates'
      AND fn_check_sequential_character(substring(cln.pan_number, 1, 5)) = 'Characters not forming sequence'
      AND fn_check_sequential_character(substring(cln.pan_number, 6, 4)) = 'Characters not forming sequence'
      AND cln.pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
)
SELECT cln.pan_number,
       CASE
           WHEN vld.pan_number IS NOT NULL THEN 'Valid PAN'
           ELSE 'Invalid PAN'
       END AS status
FROM cte_cleaned_pan cln
LEFT JOIN cte_valid_pan vld 
ON cln.pan_number = vld.pan_number;

-- View sample results
SELECT *
FROM PAN_status
LIMIT 10;


-- ==========================================
-- STEP 6: Summary Report
-- ==========================================
WITH cte AS (
    SELECT
        (SELECT COUNT(*) FROM stg_pan_num_dataset) AS total_processed_records,
        COUNT(*) FILTER (WHERE status = 'Valid PAN') AS total_valid_PANs,
        COUNT(*) FILTER (WHERE status = 'Invalid PAN') AS total_invalid_PANs
    FROM PAN_status
)
SELECT total_processed_records,
       total_valid_PANs,
       total_invalid_PANs,
       total_processed_records - (total_valid_PANs + total_invalid_PANs) AS total_missing_pans
FROM cte;
