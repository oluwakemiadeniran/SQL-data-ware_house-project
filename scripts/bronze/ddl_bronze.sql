/*
=============================================================
DDL Script: Bronze Layer
=============================================================
Purpose:
    Create tables for the Bronze layer of the data warehouse.

Source Systems:
    - CRM
    - ERP

Tables Created:
    CRM:
        - bronze.crm_cust_info
        - bronze.crm_prd_info
        - bronze.crm_sales_details

    ERP:
        - bronze.erp_CUST_AZ12
        - bronze.erp_LOC_A101
        - bronze.erp_PX_CAT_G1V2
=============================================================
*/


-- ============================================================
-- Create Bronze Schema
-- ============================================================

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'bronze'
)
BEGIN
    EXEC('CREATE SCHEMA bronze');
END;
GO


-- ============================================================
-- CRM Tables
-- ============================================================

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);
GO


IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(100),
    prd_cost DECIMAL(10,2),
    prd_line NVARCHAR(20),
    prd_start_dt DATE,
    prd_end_dt DATE
);
GO


IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt NVARCHAR(20),
    sls_ship_dt NVARCHAR(20),
    sls_due_dt NVARCHAR(20),
    sls_sales DECIMAL(12,2),
    sls_quantity INT,
    sls_price DECIMAL(12,2)
);
GO


-- ============================================================
-- ERP Tables
-- ============================================================

IF OBJECT_ID('bronze.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_CUST_AZ12;
GO

CREATE TABLE bronze.erp_CUST_AZ12 (
    CID NVARCHAR(20),
    BDATE DATE,
    GEN NVARCHAR(20)
);
GO


IF OBJECT_ID('bronze.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_LOC_A101;
GO

CREATE TABLE bronze.erp_LOC_A101 (
    CID NVARCHAR(20),
    CNTRY NVARCHAR(100)
);
GO


IF OBJECT_ID('bronze.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_PX_CAT_G1V2;
GO

CREATE TABLE bronze.erp_PX_CAT_G1V2 (
    ID NVARCHAR(20),
    CAT NVARCHAR(50),
    SUBCAT NVARCHAR(100),
    MAINTENANCE NVARCHAR(10)
);
GO
