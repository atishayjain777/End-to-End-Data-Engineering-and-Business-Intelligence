-- Database_Setup


01_Create_Database.sql


-- Drop database if already exists
DROP DATABASE IF EXISTS global_estore_raw;

-- Create database
CREATE DATABASE global_estore_raw;

-- Use database
USE global_estore_raw;






02_Database_Settings.sql


-- Check current database
SELECT DATABASE();

-- Check MySQL version
SELECT VERSION();

-- Show available databases
SHOW DATABASES;

-- Show all tables
SHOW TABLES;



03_Table_Count.sql

-- Count total tables
SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'global_estore_raw';



04_Database_Metadata.sql

-- Database size
SELECT
table_schema AS database_name,
ROUND(SUM(data_length + index_length)/1024/1024,2) AS size_mb
FROM information_schema.tables
WHERE table_schema='global_estore_raw'
GROUP BY table_schema;

-- Table status
SHOW TABLE STATUS;


