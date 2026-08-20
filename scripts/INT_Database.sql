```sql
-- ============================================================
-- Data Warehouse Project
-- Database and Schema Initialization
-- ============================================================
-- Purpose:
-- Creates the DataWarehouse database and the three schemas
-- used in the data warehouse architecture.
--
--
--Tool used:
--Microsoft SQL server
--
--
-- Bronze: Raw/source data
-- Silver: Cleaned and transformed data
-- Gold: Business-ready data for analysis and reporting
-- ============================================================


-- Switch to the system database
USE master;
GO


-- Create the DataWarehouse database if it does not already exist
IF DB_ID('DataWarehouse') IS NULL
BEGIN
    CREATE DATABASE DataWarehouse;
END;
GO


-- Switch to the DataWarehouse database
USE DataWarehouse;
GO


-- Create Bronze schema
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'bronze'
)
BEGIN
    EXEC('CREATE SCHEMA bronze');
END;
GO


-- Create Silver schema
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'silver'
)
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO


-- Create Gold schema
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'gold'
)
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO


-- Verify the schemas
SELECT name AS schema_name
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold');
GO
```
