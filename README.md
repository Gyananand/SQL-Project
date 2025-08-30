# PAN Number Validation Project

---

## **Project Overview**

This project focuses on **validating and categorizing Indian PAN numbers** from a dataset. The goal is to ensure **data quality** by identifying valid, invalid, and missing PAN records. It combines **data cleaning, preprocessing, and rule-based validation** using SQL, PL/pgSQL functions, and regular expressions.

---

## **Project Steps**

### 1. Data Cleaning and Preprocessing

* Handle missing values (`NULL` or empty strings)
* Remove duplicate PAN numbers
* Trim leading/trailing spaces
* Convert all letters to uppercase

### 2. Custom Validation Functions

* **`fn_check_adjacent_character(p_str)`**: Checks for adjacent duplicate characters
* **`fn_check_sequential_character(p_str)`**: Checks if characters form a sequence (e.g., `ABCDE` or `1234`)

### 3. PAN Structure Validation

* Regular expression used: `^[A-Z]{5}[0-9]{4}[A-Z]$`
* Ensures the PAN follows the standard format `AAAAA1234A`

### 4. Categorization

* PANs are classified as:

  * **Valid PAN**: Meets all rules
  * **Invalid PAN**: Violates any rule

* A **SQL view (`PAN_status`)** is created to easily query PAN status.

### 5. Summary Report

* Displays:

  * Total records processed
  * Total valid PANs
  * Total invalid PANs
  * Total missing/incomplete PANs

---

## **Sample Results**

| PAN Number | Status      |
| ---------- | ----------- |
| AHGVE1276F | Valid PAN   |
| ABCDE1234F | Invalid PAN |
| AAXYZ1234Z | Invalid PAN |

**Summary Table:**

| Metric                  | Count  | Percentage |
| ----------------------- | ------ | ---------- |
| Total Records Processed | 10,000 | 100%       |
| Valid PANs              | 3,186  | 31.86%     |
| Invalid PANs            | 5,839  | 58.39%     |
| Missing/Incomplete PANs | 975    | 9.75%      |

---

## **How to Run**

1. Clone or download the repository.

2. Open `PAN_Validation_Project.sql` in PostgreSQL.

3. Run the SQL script to:

   * Create the table
   * Clean and preprocess data
   * Validate PAN numbers
   * Create `PAN_status` view
   * Generate summary report

4. Query the `PAN_status` view to check individual PAN validation results.

```sql
SELECT * 
FROM PAN_status
LIMIT 10;
```

---

## **Key Takeaways**

* Only **\~31% of PANs were valid**, highlighting significant data quality issues.
* Rule-based validation with custom functions ensures **systematic and reusable data quality checks**.
* The SQL view `PAN_status` can be reused for **ongoing PAN data monitoring**.

---

## **Skills & Technologies Applied**

* SQL & PL/pgSQL
* Data Cleaning & Preprocessing
* Regular Expressions
* Data Validation & Categorization
* Creating SQL Views for reusable data pipelines
---

