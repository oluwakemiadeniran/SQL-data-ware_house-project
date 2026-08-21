USE DataWarehouse;
GO

/*==============================================================================
    Stored Procedure: silver.load_silver
    ----------------------------------------------------------------------------
    Purpose:
        Loads and transforms data from the Bronze layer into the Silver layer.

        The Silver layer contains cleaned, standardized, and transformed data
        that is ready for downstream analysis and the Gold layer.

    Process:
        1. Truncate existing Silver tables.
        2. Extract data from Bronze tables.
        3. Clean and standardize the data.
        4. Load the transformed data into Silver tables.
        5. Track execution time for each table.
        6. Use a transaction to ensure the load completes successfully.
        7. Roll back the transaction if an error occurs.

    Refresh Strategy:
        Full Refresh - Silver tables are truncated and reloaded during each run.

    Usage:
        EXEC silver.load_silver;
==============================================================================*/


CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    SET NOCOUNT ON;


    /*==========================================================================
        Variable Declaration
    ==========================================================================*/

    DECLARE @StartTime       DATETIME2;
    DECLARE @EndTime         DATETIME2;
    DECLARE @SilverStartTime DATETIME2;
    DECLARE @SilverEndTime   DATETIME2;


    /*==========================================================================
        Start Silver Layer Load Timer
    ==========================================================================*/

    SET @SilverStartTime = SYSDATETIME();


    BEGIN TRY

        /*======================================================================
            Begin Transaction

            Ensures that the Silver layer is not left partially loaded if an
            error occurs during the ETL process.
        ======================================================================*/

        BEGIN TRANSACTION;


        PRINT '================================================================';
        PRINT '                  SILVER LAYER LOAD STARTED';
        PRINT '================================================================';


        /*======================================================================
            CRM: Customer Information
        ======================================================================*/

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading CRM: Customer Information...';

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,

            -- Remove leading and trailing whitespace
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            -- Standardize marital status
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                    THEN 'Married'

                WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                    THEN 'Single'

                ELSE 'Unknown'
            END AS cst_marital_status,

            -- Standardize gender
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F'
                    THEN 'Female'

                WHEN UPPER(TRIM(cst_gndr)) = 'M'
                    THEN 'Male'

                ELSE 'Unknown'
            END AS cst_gndr,

            cst_create_date

        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last

            FROM bronze.crm_cust_info

            -- Exclude records without a customer ID
            WHERE cst_id IS NOT NULL

        ) AS t

        -- Keep only the most recent record for each customer
        WHERE flag_last = 1;


        SET @EndTime = SYSDATETIME();

        PRINT 'CRM Customer Information loaded successfully.';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @StartTime,
                    @EndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';


        /*======================================================================
            CRM: Product Information
        ======================================================================*/

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading CRM: Product Information...';

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            -- Convert category code format
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ) AS cat_id,

            -- Extract product key
            SUBSTRING(
                prd_key,
                7,
                LEN(prd_key)
            ) AS prd_key,

            prd_nm,

            -- Replace missing product cost with zero
            ISNULL(prd_cost, 0) AS prd_cost,

            -- Standardize product line
            CASE UPPER(TRIM(prd_line))

                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'

                ELSE 'Unknown'

            END AS prd_line,

            prd_start_dt,

            -- Generate product end date based on the next start date
            DATEADD(
                DAY,
                -1,
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                )
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;


        SET @EndTime = SYSDATETIME();

        PRINT 'CRM Product Information loaded successfully.';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @StartTime,
                    @EndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';


        /*======================================================================
            CRM: Sales Details
        ======================================================================*/

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading CRM: Sales Details...';

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Convert order date from YYYYMMDD format
            CASE
                WHEN sls_order_dt = 0
                     OR LEN(sls_order_dt) != 8
                    THEN NULL

                ELSE CAST(
                    CAST(sls_order_dt AS VARCHAR) AS DATE
                )
            END AS sls_order_dt,

            -- Convert shipping date
            CASE
                WHEN sls_ship_dt = 0
                     OR LEN(sls_ship_dt) != 8
                    THEN NULL

                ELSE CAST(
                    CAST(sls_ship_dt AS VARCHAR) AS DATE
                )
            END AS sls_ship_dt,

            -- Convert due date
            CASE
                WHEN sls_due_dt = 0
                     OR LEN(sls_due_dt) != 8
                    THEN NULL

                ELSE CAST(
                    CAST(sls_due_dt AS VARCHAR) AS DATE
                )
            END AS sls_due_dt,

            -- Validate and recalculate sales amount
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales != sls_quantity * ABS(sls_price)

                    THEN sls_quantity * ABS(sls_price)

                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Validate and standardize price
            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0

                    THEN ROUND(
                        sls_sales / NULLIF(sls_quantity, 0),
                        2
                    )

                ELSE ROUND(sls_price, 2)

            END AS sls_price

        FROM bronze.crm_sales_details;


        SET @EndTime = SYSDATETIME();

        PRINT 'CRM Sales Details loaded successfully.';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @StartTime,
                    @EndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';


        /*======================================================================
            ERP: Customer Information
        ======================================================================*/

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading ERP: Customer Information...';

        TRUNCATE TABLE silver.erp_CUST_AZ12;

        INSERT INTO silver.erp_CUST_AZ12 (
            CID,
            BDATE,
            GEN
        )
        SELECT

            -- Remove NAS prefix from customer ID
            CASE
                WHEN CID LIKE 'NAS%'
                    THEN SUBSTRING(
                        CID,
                        4,
                        LEN(CID)
                    )

                ELSE CID
            END AS CID,

            -- Remove future birth dates
            CASE
                WHEN BDATE > GETDATE()
                    THEN NULL

                ELSE BDATE
            END AS BDATE,

            -- Standardize gender values
            CASE
                WHEN LEFT(
                    UPPER(
                        LTRIM(
                            RTRIM(GEN)
                        )
                    ),
                    1
                ) = 'F'
                    THEN 'Female'

                WHEN LEFT(
                    UPPER(
                        LTRIM(
                            RTRIM(GEN)
                        )
                    ),
                    1
                ) = 'M'
                    THEN 'Male'

                ELSE 'Unknown'

            END AS GEN

        FROM bronze.erp_CUST_AZ12;


        SET @EndTime = SYSDATETIME();

        PRINT 'ERP Customer Information loaded successfully.';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @StartTime,
                    @EndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';


        /*======================================================================
            ERP: Location Information
        ======================================================================*/

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading ERP: Location Information...';

        TRUNCATE TABLE silver.erp_LOC_A101;


        /*----------------------------------------------------------------------
            Clean location data before inserting into Silver.
        ----------------------------------------------------------------------*/

        WITH Cleaned AS (
            SELECT
                REPLACE(
                    CID,
                    '-',
                    ''
                ) AS CID,

                UPPER(
                    TRIM(
                        REPLACE(
                            REPLACE(
                                CNTRY,
                                CHAR(13),
                                ''
                            ),
                            CHAR(10),
                            ''
                        )
                    )
                ) AS CNTRY

            FROM bronze.erp_LOC_A101
        )


        INSERT INTO silver.erp_LOC_A101 (
            CID,
            CNTRY
        )
        SELECT
            CID,

            -- Standardize country values
            CASE
                WHEN CNTRY = 'DE'
                    THEN 'GERMANY'

                WHEN CNTRY IN ('US', 'USA')
                    THEN 'UNITED STATES'

                WHEN CNTRY = ''
                     OR CNTRY IS NULL
                    THEN 'Unknown'

                ELSE CNTRY

            END AS CNTRY

        FROM Cleaned;


        SET @EndTime = SYSDATETIME();

        PRINT 'ERP Location Information loaded successfully.';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @StartTime,
                    @EndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';


        /*======================================================================
            ERP: Product Category
        ======================================================================*/

        SET @StartTime = SYSDATETIME();

        PRINT 'Loading ERP: Product Category...';

        TRUNCATE TABLE silver.erp_PX_CAT_G1V2;

        INSERT INTO silver.erp_PX_CAT_G1V2 (
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        )
        SELECT
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE

        FROM bronze.erp_PX_CAT_G1V2;


        SET @EndTime = SYSDATETIME();

        PRINT 'ERP Product Category loaded successfully.';
        PRINT 'Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @StartTime,
                    @EndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';


        /*======================================================================
            Commit Transaction
        ======================================================================*/

        COMMIT TRANSACTION;


        /*======================================================================
            Calculate Total Execution Time
        ======================================================================*/

        SET @SilverEndTime = SYSDATETIME();


        PRINT '================================================================';
        PRINT '                  SILVER LAYER LOAD COMPLETED';
        PRINT '================================================================';

        PRINT 'Total Execution Time: '
            + CAST(
                DATEDIFF(
                    MILLISECOND,
                    @SilverStartTime,
                    @SilverEndTime
                ) AS NVARCHAR(20)
            )
            + ' ms';

        PRINT '================================================================';


    END TRY


    /*======================================================================
        Error Handling
    ======================================================================*/

    BEGIN CATCH

        -- Roll back transaction if an error occurs
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;


        PRINT '================================================================';
        PRINT '                  SILVER LAYER LOAD FAILED';
        PRINT '================================================================';

        PRINT 'Error Number: '
            + CAST(
                ERROR_NUMBER()
                AS NVARCHAR(20)
            );

        PRINT 'Error Message: '
            + ERROR_MESSAGE();

        PRINT 'Error Line: '
            + CAST(
                ERROR_LINE()
                AS NVARCHAR(20)
            );

        PRINT 'Error Procedure: '
            + ISNULL(
                ERROR_PROCEDURE(),
                'N/A'
            );

        PRINT '================================================================';


        -- Return the original error to the caller
        THROW;

    END CATCH;

END;
GO
