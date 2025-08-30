CREATE TABLE stg_pan_num_dataset (pan_numbers text);


SELECT count(*)
FROM stg_pan_num_dataset;

--A. Data Cleaning and Preprocessing:
 --1. Identifying and handling missing data

SELECT count(*)
FROM stg_pan_num_dataset spnd
WHERE pan_numbers IS NULL
AND pan_numbers = '';

--2. Check for duplicates:

SELECT pan_numbers,
       count(1) AS duplicates
FROM stg_pan_num_dataset spnd
GROUP BY pan_numbers
HAVING count(1) > 1;

--3. Handle leading/trailing spaces:

SELECT *
FROM stg_pan_num_dataset spnd
WHERE pan_numbers != TRIM(pan_numbers);

-- 4. Correct letter case

SELECT count(pan_numbers) AS total_letter_case
FROM stg_pan_num_dataset spnd
WHERE pan_numbers != UPPER(pan_numbers);

--5. Cleaned Pan Numbers

SELECT DISTINCT UPPER(TRIM(pan_numbers))
FROM stg_pan_num_dataset spnd
WHERE TRIM(pan_numbers) != ''
LIMIT ;

-- Function to check if adjacent characters are same

CREATE OR REPLACE FUNCTION fn_check_adjacent_character(p_str text) RETURNS text LANGUAGE PLPGSQL AS $$
begin
    for i in 1.. (length(p_str) - 1) loop
        if substring(p_str, i, 1) = substring(p_str, i+1, 1) then
            return 'Has adjacent duplicates';
        end if;
    end loop;
    return 'No adjacent duplicates';
end;
$$;


SELECT fn_check_adjacent_character('abdef') -- Function to check characters cannot form a sequence

CREATE OR REPLACE FUNCTION fn_check_sequential_character(p_str text) RETURNS text LANGUAGE PLPGSQL AS $$
declare
    is_seq boolean := true;
begin
    for i in 1..(length(p_str) - 1) loop
        if ascii(substring(p_str, i+1, 1)) - ascii(substring(p_str, i, 1)) != 1 then
            is_seq := false;
            exit;
        end if;
    end loop;

    if is_seq then
        return 'Characters forming sequence';
    else
        return 'Characters not forming sequence';
    end if;
end;
$$;


SELECT ascii('A');


SELECT fn_check_sequential_character('ABCDF');

-- Regular expression to validate the pattern or structure of PAN Number (AAAAA1234A)

SELECT *
FROM stg_pan_num_dataset spnd
WHERE pan_numbers ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
LIMIT 10;

-- Valid and Invalid pan Categorization

CREATE OR REPLACE VIEW PAN_status AS 
WITH cte_cleaned_pan AS
	  (SELECT DISTINCT UPPER(TRIM(pan_numbers)) pan_number
	   FROM stg_pan_num_dataset spnd
	   WHERE TRIM(pan_numbers) != ''),
      cte_valid_pan AS
	  (SELECT *
	   FROM cte_cleaned_pan cln
	   WHERE fn_check_adjacent_character(cln.pan_number) = 'No adjacent duplicates'
	     AND fn_check_sequential_character(substring(cln.pan_number, 1, 5)) = 'Characters not forming sequence'
	     AND fn_check_sequential_character(substring(cln.pan_number, 6, 4)) = 'Characters not forming sequence'
	     AND cln.pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$')
SELECT cln.pan_number,
       CASE
           WHEN vld.pan_number IS NOT NULL THEN 'Valid PAN'
           ELSE 'Invalid PAN'
       END AS status
FROM cte_cleaned_pan cln
LEFT JOIN cte_valid_pan vld ON cln.pan_number = vld.pan_number;


SELECT *
FROM pan_status
LIMIT 10;

-- Summary Report
 WITH cte AS
  (SELECT
     (SELECT count(*)
      FROM stg_pan_num_dataset) AS total_processed_records,
          count(*) filter(
                          WHERE status = 'Valid PAN') AS total_valid_PANs,
          count(*) filter(
                          WHERE status = 'Invalid PAN') AS total_invalid_PANs
   FROM pan_status)
SELECT total_processed_records,
       total_valid_PANs,
       total_invalid_PANs,
       total_processed_records - (total_valid_PANs + total_invalid_PANs) AS total_missing_pans
FROM cte


