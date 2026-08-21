USE DataWarehouse;
GO

/*==============================================================================
    Create Silver Layer Tables
    ----------------------------------------------------------------------------
    Purpose:
        Creates the Silver layer tables used to store cleaned and transformed
        data from the Bronze layer.

    Notes:
        - Existing Silver tables are dropped before recreation.
        - dwh_create_date records the timestamp when a row is inserted.
        - This script is intended for initial setup / schema recreation.
==============================================================================*/


/*==============================================================================
    CRM: Customer Information
==============================================================================*/

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME2 DEFAULT SYSDATETIME()
);
GO


/*==============================================================================
    CRM: Product Information
==============================================================================*/

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(100),
    prd_cost        DECIMAL(10, 2),
    prd_line        NVARCHAR(20),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date DATETIME2 DEFAULT SYSDATETIME()
);
GO


/*==============================================================================
    CRM: Sales Details
==============================================================================*/

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    NVARCHAR(20),
    sls_ship_dt     NVARCHAR(20),
    sls_due_dt      NVARCHAR(20),
    sls_sales       DECIMAL(12, 2),
    sls_quantity    INT,
    sls_price       DECIMAL(12, 2),
    dwh_create_date DATETIME2 DEFAULT SYSDATETIME()
);
GO


/*==============================================================================
    ERP: Customer Information
==============================================================================*/

IF OBJECT_ID('silver.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE silver.erp_CUST_AZ12;
GO

CREATE TABLE silver.erp_CUST_AZ12 (
    CID             NVARCHAR(20),
    BDATE           DATE,
    GEN             NVARCHAR(20),
    dwh_create_date DATETIME2 DEFAULT SYSDATETIME()
);
GO


/*==============================================================================
    ERP: Location Information
==============================================================================*/

IF OBJECT_ID('silver.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE silver.erp_LOC_A101;
GO

CREATE TABLE silver.erp_LOC_A101 (
    CID             NVARCHAR(20),
    CNTRY           NVARCHAR(100),
    dwh_create_date DATETIME2 DEFAULT SYSDATETIME()
);
GO


/*==============================================================================
    ERP: Product Category Information
==============================================================================*/

IF OBJECT_ID('silver.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE silver.erp_PX_CAT_G1V2;
GO

CREATE TABLE silver.erp_PX_CAT_G1V2 (
    ID              NVARCHAR(20),
    CAT             NVARCHAR(50),
    SUBCAT          NVARCHAR(100),
    MAINTENANCE     NVARCHAR(10),
    dwh_create_date DATETIME2 DEFAULT SYSDATETIME()
);
GO
