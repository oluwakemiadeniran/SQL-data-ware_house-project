-- ============================================================
-- Data Warehouse Project
-- Database Initialization Script
-- ============================================================
-- Purpose:
-- Create the databases used for the Bronze, Silver, and Gold
-- layers of the data warehouse.
--
--Tool used:
--MYsql
--
-- Bronze: Raw data
-- Silver: Cleaned and transformed data
-- Gold: Business-ready data for analysis and reporting
-- ============================================================

-- Create Bronze layer
CREATE DATABASE IF NOT EXISTS DataWarehouse_Bronze;

-- Create Silver layer
CREATE DATABASE IF NOT EXISTS DataWarehouse_Silver;

-- Create Gold layer
CREATE DATABASE IF NOT EXISTS DataWarehouse_Gold;
