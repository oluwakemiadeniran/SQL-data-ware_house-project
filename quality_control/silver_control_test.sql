```sql
/*
===============================================================================
Silver Layer Data Quality Checks
===============================================================================
Script Purpose:
    This script performs data quality checks on the Silver layer to identify
    issues related to:

    - NULL and duplicate primary keys
    - Unwanted spaces
    - Data standardization and consistency
    - Invalid dates
    - Invalid numeric values
    - Referential integrity
    - Cross-column data consistency
    - Product validity periods
    - Customer and location standardization

Usage:
    Run these checks after loading the Silver layer.

Expectation:
    Queries labelled "Expectation: No Results" should return zero rows.
    Queries returning DISTINCT values are used to manually inspect
    standardization and consistency.

Important:
    These checks are for validation only. They do not modify the data.
===============================================================================
*/


/*
===============================================================================
1. Checking silver.crm_cust_info
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check for NULLs or Duplicate Primary Keys
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- --------------------------------------------------------------------
-- Check for Unwanted Spaces in Customer Key
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);


-- --------------------------------------------------------------------
-- Check for Unwanted Spaces in First Name
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);


-- --------------------------------------------------------------------
-- Check for Unwanted Spaces in Last Name
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);


-- --------------------------------------------------------------------
-- Data Standardization & Consistency
-- --------------------------------------------------------------------
SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- --------------------------------------------------------------------
-- Check for NULLs in Important Customer Attributes
-- --------------------------------------------------------------------
SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname IS NULL
   OR cst_lastname IS NULL;


/*
===============================================================================
2. Checking silver.crm_prd_info
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check for NULLs or Duplicate Primary Keys
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;


-- --------------------------------------------------------------------
-- Check for Unwanted Spaces in Product Name
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


-- --------------------------------------------------------------------
-- Check for NULL or Negative Product Cost
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    prd_id,
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;


-- --------------------------------------------------------------------
-- Data Standardization & Consistency
-- --------------------------------------------------------------------
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- --------------------------------------------------------------------
-- Check for Invalid Product Date Ranges
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    *
FROM silver.crm_prd_info
WHERE prd_start_dt IS NULL
   OR prd_end_dt IS NULL
   OR prd_end_dt < prd_start_dt;


-- --------------------------------------------------------------------
-- Check Product Date Overlaps / Incorrect End Dates
-- This validates whether the end date of one product version
-- correctly precedes the next start date.
-- --------------------------------------------------------------------
SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,

    DATEADD(
        DAY,
        -1,
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        )
    ) AS expected_end_dt

FROM silver.crm_prd_info
WHERE prd_key IS NOT NULL;


-- --------------------------------------------------------------------
-- Check Product Category Mapping
-- Every product category should exist in the category table.
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    prd_id,
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    prd_nm
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')
      NOT IN (
          SELECT DISTINCT id
          FROM bronze.erp_PX_CAT_G1V2
      );


-- --------------------------------------------------------------------
-- Check Product Keys Against Sales Data
-- Products appearing in sales should exist in the product master.
-- --------------------------------------------------------------------
SELECT DISTINCT
    SUBSTRING(sls_prd_key, 7, LEN(sls_prd_key)) AS prd_key
FROM bronze.crm_sales_details
WHERE SUBSTRING(sls_prd_key, 7, LEN(sls_prd_key))
      NOT IN (
          SELECT DISTINCT prd_key
          FROM silver.crm_prd_info
      );


/*
===============================================================================
3. Checking silver.crm_sales_details
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check for Invalid Customer IDs
-- Every sales customer should exist in the customer master.
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT cst_id
    FROM silver.crm_cust_info
);


-- --------------------------------------------------------------------
-- Check for Invalid Product Keys
-- Every sales product should exist in the product master.
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    sls_ord_num,
    sls_prd_key
FROM silver.crm_sales_details
WHERE SUBSTRING(sls_prd_key, 7, LEN(sls_prd_key))
      NOT IN (
          SELECT DISTINCT prd_key
          FROM silver.crm_prd_info
      );


-- --------------------------------------------------------------------
-- Check for Invalid Order Dates in Bronze
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
   OR LEN(sls_order_dt) != 8
   OR sls_order_dt > 20500101
   OR sls_order_dt < 19000101;


-- --------------------------------------------------------------------
-- Check for Invalid Shipping Dates
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
   OR LEN(sls_ship_dt) != 8
   OR sls_ship_dt > 20500101
   OR sls_ship_dt < 19000101;


-- --------------------------------------------------------------------
-- Check for Invalid Due Dates
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LEN(sls_due_dt) != 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;


-- --------------------------------------------------------------------
-- Check Order Date Against Shipping and Due Dates
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;


-- --------------------------------------------------------------------
-- Check Shipping Date Against Due Date
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_ship_dt > sls_due_dt;


-- --------------------------------------------------------------------
-- Check Sales Calculation
-- Sales should equal Quantity * Price.
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;


/*
===============================================================================
4. Checking silver.erp_cust_az12
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check Customer ID Standardization
-- --------------------------------------------------------------------
SELECT
    CASE
        WHEN CID LIKE 'NAS%'
            THEN SUBSTRING(CID, 4, LEN(CID))
        ELSE CID
    END AS CID,
    BDATE,
    GEN
FROM bronze.erp_CUST_AZ12;


-- --------------------------------------------------------------------
-- Check for Invalid Birth Dates
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    BDATE
FROM silver.erp_cust_az12
WHERE BDATE < '1900-01-01'
   OR BDATE > GETDATE();


-- --------------------------------------------------------------------
-- Data Standardization & Consistency for Gender
-- --------------------------------------------------------------------
SELECT DISTINCT
    GEN
FROM silver.erp_cust_az12;


-- --------------------------------------------------------------------
-- Detailed Gender Standardization Check
-- --------------------------------------------------------------------
SELECT DISTINCT
    GEN AS old_GEN,

    CASE
        WHEN LEFT(UPPER(LTRIM(RTRIM(GEN))), 1) = 'F'
            THEN 'Female'

        WHEN LEFT(UPPER(LTRIM(RTRIM(GEN))), 1) = 'M'
            THEN 'Male'

        ELSE 'Unknown'
    END AS new_GEN

FROM bronze.erp_CUST_AZ12;


/*
===============================================================================
5. Checking silver.erp_loc_a101
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check Customer ID Formatting
-- --------------------------------------------------------------------
SELECT
    REPLACE(CID, '-', '') AS CID,

    CASE
        WHEN UPPER(LTRIM(RTRIM(CNTRY))) = 'DE'
            THEN 'Germany'

        WHEN UPPER(LTRIM(RTRIM(CNTRY))) IN ('US', 'USA')
            THEN 'United States'

        WHEN LTRIM(RTRIM(CNTRY)) = ''
             OR CNTRY IS NULL
            THEN 'Unknown'

        ELSE LTRIM(RTRIM(CNTRY))
    END AS CNTRY

FROM bronze.erp_LOC_A101;


-- --------------------------------------------------------------------
-- Data Standardization & Consistency
-- --------------------------------------------------------------------
SELECT DISTINCT
    CNTRY
FROM silver.erp_LOC_A101
ORDER BY CNTRY;


-- --------------------------------------------------------------------
-- Check for Unwanted Spaces in Country
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    CNTRY
FROM silver.erp_LOC_A101
WHERE CNTRY != TRIM(CNTRY);


-- --------------------------------------------------------------------
-- Check for NULL Customer IDs
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    *
FROM silver.erp_LOC_A101
WHERE CID IS NULL;


/*
===============================================================================
6. Checking silver.erp_px_cat_g1v2
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check for Unwanted Spaces
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE CAT != TRIM(CAT)
   OR SUBCAT != TRIM(SUBCAT)
   OR MAINTENANCE != TRIM(MAINTENANCE);


-- --------------------------------------------------------------------
-- Data Standardization & Consistency
-- --------------------------------------------------------------------
SELECT DISTINCT
    MAINTENANCE
FROM silver.erp_px_cat_g1v2;


-- --------------------------------------------------------------------
-- Check for NULL Category IDs
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE ID IS NULL;


-- --------------------------------------------------------------------
-- Check for Duplicate Category IDs
-- Expectation: No Results
-- --------------------------------------------------------------------
SELECT
    ID,
    COUNT(*) AS record_count
FROM silver.erp_px_cat_g1v2
GROUP BY ID
HAVING COUNT(*) > 1;


/*
===============================================================================
7. Cross-Table Referential Integrity Checks
===============================================================================
*/

-- --------------------------------------------------------------------
-- Check Customer IDs Between Customer Master and ERP Customer Data
-- --------------------------------------------------------------------
SELECT
    cst_id
FROM silver.crm_cust_info
WHERE cst_id NOT IN (
    SELECT
        CASE
            WHEN CID LIKE 'NAS%'
                THEN SUBSTRING(CID, 4, LEN(CID))
            ELSE CID
        END
    FROM bronze.erp_CUST_AZ12
);


-- --------------------------------------------------------------------
-- Check Customer IDs Between CRM and Location Data
-- --------------------------------------------------------------------
SELECT
    cst_id
FROM silver.crm_cust_info
WHERE cst_id NOT IN (
    SELECT REPLACE(CID, '-', '')
    FROM silver.erp_LOC_A101
);


/*
===============================================================================
8. General Silver Layer Review
===============================================================================
*/

-- Review Customer Data
SELECT *
FROM silver.crm_cust_info;


-- Review Product Data
SELECT *
FROM silver.crm_prd_info;


-- Review Sales Data
SELECT *
FROM silver.crm_sales_details;


-- Review ERP Customer Data
SELECT *
FROM silver.erp_cust_az12;


-- Review ERP Location Data
SELECT *
FROM silver.erp_loc_a101;


-- Review ERP Category Data
SELECT *
FROM silver.erp_px_cat_g1v2;
```
