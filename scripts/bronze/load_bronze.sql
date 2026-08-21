/*
=============================================================
Load Script: Bronze Layer
=============================================================
Purpose:
    Load raw CRM and ERP CSV files into the Bronze layer.

IMPORTANT:
    Update the file paths below to match the location of the
    datasets on your local machine.

Source Systems:
    - CRM
    - ERP
=============================================================
*/


-- ============================================================
-- Create Bronze Loading Procedure
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME;
    DECLARE @EndTime DATETIME;

    SET @StartTime = GETDATE();


    PRINT '============================================';
    PRINT 'Starting Bronze Layer Load';
    PRINT '============================================';


    -- ========================================================
    -- CRM: Customer Information
    -- ========================================================

    PRINT 'Loading bronze.crm_cust_info...';

    TRUNCATE TABLE bronze.crm_cust_info;

    BULK INSERT bronze.crm_cust_info
    FROM 'C:\Path\To\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT 'crm_cust_info loaded successfully.';


    -- ========================================================
    -- CRM: Product Information
    -- ========================================================

    PRINT 'Loading bronze.crm_prd_info...';

    TRUNCATE TABLE bronze.crm_prd_info;

    BULK INSERT bronze.crm_prd_info
    FROM 'C:\Path\To\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT 'crm_prd_info loaded successfully.';


    -- ========================================================
    -- CRM: Sales Details
    -- ========================================================

    PRINT 'Loading bronze.crm_sales_details...';

    TRUNCATE TABLE bronze.crm_sales_details;

    BULK INSERT bronze.crm_sales_details
    FROM 'C:\Path\To\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT 'crm_sales_details loaded successfully.';


    -- ========================================================
    -- ERP: Customer Information
    -- ========================================================

    PRINT 'Loading bronze.erp_CUST_AZ12...';

    TRUNCATE TABLE bronze.erp_CUST_AZ12;

    BULK INSERT bronze.erp_CUST_AZ12
    FROM 'C:\Path\To\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT 'erp_CUST_AZ12 loaded successfully.';


    -- ========================================================
    -- ERP: Location Information
    -- ========================================================

    PRINT 'Loading bronze.erp_LOC_A101...';

    TRUNCATE TABLE bronze.erp_LOC_A101;

    BULK INSERT bronze.erp_LOC_A101
    FROM 'C:\Path\To\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT 'erp_LOC_A101 loaded successfully.';


    -- ========================================================
    -- ERP: Product Category Information
    -- ========================================================

    PRINT 'Loading bronze.erp_PX_CAT_G1V2...';

    TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;

    BULK INSERT bronze.erp_PX_CAT_G1V2
    FROM 'C:\Path\To\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

    PRINT 'erp_PX_CAT_G1V2 loaded successfully.';


    -- ========================================================
    -- Record Completion Time
    -- ========================================================

    SET @EndTime = GETDATE();


    PRINT '============================================';
    PRINT 'Bronze Layer Load Completed';
    PRINT '============================================';

    PRINT 'Start Time: ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT 'End Time:   ' + CONVERT(VARCHAR, @EndTime, 120);

END;
GO


-- ============================================================
-- Execute Bronze Load
-- ============================================================

EXEC bronze.load_bronze;
GO


-- ============================================================
-- Data Validation
-- ============================================================

SELECT
    'crm_cust_info' AS Table_Name,
    COUNT(*) AS Row_Count
FROM bronze.crm_cust_info

UNION ALL

SELECT
    'crm_prd_info',
    COUNT(*)
FROM bronze.crm_prd_info

UNION ALL

SELECT
    'crm_sales_details',
    COUNT(*)
FROM bronze.crm_sales_details

UNION ALL

SELECT
    'erp_CUST_AZ12',
    COUNT(*)
FROM bronze.erp_CUST_AZ12

UNION ALL

SELECT
    'erp_LOC_A101',
    COUNT(*)
FROM bronze.erp_LOC_A101

UNION ALL

SELECT
    'erp_PX_CAT_G1V2',
    COUNT(*)
FROM bronze.erp_PX_CAT_G1V2;
GO
