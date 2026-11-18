--Data validation queries to compare totals db and dw Customer
SELECT
    (SELECT COUNT(*)
     FROM RentalDB.dbo.Customer) AS Operational_Customers,

    (SELECT COUNT(*)
     FROM dbo.DimCustomer) AS DW_Customers,

    (SELECT COUNT(*)
     FROM dbo.Customer)
    -
    (SELECT COUNT(*)
     FROM dbo.DimCustomer) AS Difference;
--------------
-- Data validation queries to compare totals db and dw DimModel

USE RentalDB;
GO

-- 1. Validate missing or incorrect records in DimModel
SELECT
    m.model_id,
    m.brand_name,
    m.name AS model_name,
    sc.name AS subcategory_name,
    c.name AS category_name
FROM dbo.Model AS m
INNER JOIN dbo.SubCategory AS sc
    ON m.sub_cat_id = sc.sub_cat_id
INNER JOIN dbo.Category AS c
    ON sc.category_id = c.category_id

EXCEPT

SELECT
    model_id,
    brand_name,
    model_name,
    subcategory_name,
    category_name
FROM dbo.DimModel;


-- Validate extra or incorrect records in DimModel
SELECT
    model_id,
    brand_name,
    model_name,
    subcategory_name,
    category_name
FROM dbo.DimModel

EXCEPT

SELECT
    m.model_id,
    m.brand_name,
    m.name AS model_name,
    sc.name AS subcategory_name,
    c.name AS category_name
FROM dbo.Model AS m
INNER JOIN dbo.SubCategory AS sc
    ON m.sub_cat_id = sc.sub_cat_id
INNER JOIN dbo.Category AS c
    ON sc.category_id = c.category_id;


-- Check for duplicate model IDs
SELECT
    model_id,
    COUNT(*) AS DuplicateCount
FROM dbo.DimModel
GROUP BY model_id
HAVING COUNT(*) > 1;


-- Compare row counts
SELECT
    (SELECT COUNT(*)
     FROM dbo.Model AS m
     INNER JOIN dbo.SubCategory AS sc
         ON m.sub_cat_id = sc.sub_cat_id
     INNER JOIN dbo.Category AS c
         ON sc.category_id = c.category_id
    ) AS SourceRows,

    (SELECT COUNT(*)
     FROM dbo.DimModel
    ) AS WarehouseRows;
--------- Data Validation dimEmp
SELECT
    employee_id,
    first_name,
    last_name
FROM dbo.Employee

EXCEPT

SELECT
    employee_id,
    first_name,
    last_name
FROM dbo.DimEmployee;


--Check extra or incorrect employee records
SELECT
    employee_id,
    first_name,
    last_name
FROM dbo.DimEmployee

EXCEPT

SELECT
    employee_id,
    first_name,
    last_name
FROM dbo.Employee;


-- Check duplicate employee IDs
SELECT
    employee_id,
    COUNT(*) AS DuplicateCount
FROM dbo.DimEmployee
GROUP BY employee_id
HAVING COUNT(*) > 1;


-- Compare row counts
SELECT
    (SELECT COUNT(*)
     FROM dbo.Employee) AS SourceRows,

    (SELECT COUNT(*)
     FROM dbo.DimEmployee) AS WarehouseRows;
---Validation dim RentalStation

USE RentalDB;
GO

-- Check missing or incorrect rental station records
SELECT
    rental_station_id,
    station_name,
    address,
    city,
    COALESCE(country, 'unkown') AS country,
    station_type
FROM dbo.RentalStation

EXCEPT

SELECT
    rental_station_id,
    station_name,
    address,
    city,
    country,
    station_type
FROM dbo.DimRentalStation;


-- Check extra or any incorrect rental station records
SELECT
    rental_station_id,
    station_name,
    address,
    city,
    country,
    station_type
FROM dbo.DimRentalStation

EXCEPT

SELECT
    rental_station_id,
    station_name,
    address,
    city,
    COALESCE(country, 'unkown'),
    station_type
FROM dbo.RentalStation;


-- Check duplicate rental station IDs
SELECT
    rental_station_id,
    COUNT(*) AS DuplicateCount
FROM dbo.DimRentalStation
GROUP BY rental_station_id
HAVING COUNT(*) > 1;


-- Compare row counts
SELECT
    (SELECT COUNT(*)
     FROM dbo.RentalStation) AS SourceRows,

    (SELECT COUNT(*)
     FROM dbo.DimRentalStation) AS WarehouseRows;

--- Data validation FactRentalline

SELECT COUNT(*) AS Datawarehouse_Count FROM FactRentalLine
SELECT COUNT(*) AS SourceDB_Count FROM RentalLine
SELECT * FROM dbo.EtlLog -- checking that logging works

-- Data validation dimdate

USE RentalDB;
GO

-- Get expected date range from Operational Database
DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

SELECT
    @StartDate = CAST(MIN(start_date) AS DATE),
    @EndDate = CAST(MAX(end_date) AS DATE)
FROM dbo.Rental;


-- 1. Check missing dates in DimDate
;WITH ExpectedDates AS
(
    SELECT @StartDate AS ExpectedDate
    WHERE @StartDate IS NOT NULL
      AND @EndDate IS NOT NULL
      AND @StartDate <= @EndDate

    UNION ALL

    SELECT DATEADD(DAY, 1, ExpectedDate)
    FROM ExpectedDates
    WHERE ExpectedDate < @EndDate
)
SELECT ExpectedDate AS MissingDate
FROM ExpectedDates

EXCEPT

SELECT [date]
FROM dbo.DimDate
OPTION (MAXRECURSION 0);


-- Check duplicate dates
SELECT
    [date],
    COUNT(*) AS DuplicateCount
FROM dbo.DimDate
GROUP BY [date]
HAVING COUNT(*) > 1;


-- Compare expected and actual row counts
SELECT
    @StartDate AS StartDate,
    @EndDate AS EndDate,
    CASE
        WHEN @StartDate IS NOT NULL
         AND @EndDate IS NOT NULL
         AND @StartDate <= @EndDate
        THEN DATEDIFF(DAY, @StartDate, @EndDate) + 1
        ELSE NULL
    END AS ExpectedRows,
    (SELECT COUNT(*)
     FROM dbo.DimDate) AS WarehouseRows;

--- validation for factmaintenance
SELECT
    (SELECT COUNT(*)
     FROM dbo.Maintenance) AS SourceRows,

    (SELECT COUNT(*)
     FROM dbo.FactMaintenance) AS WarehouseRows;

-- Checking for duplicate maintenance IDs
-- 3. Check duplicate maintenance IDs
SELECT
    maintenance_id,
    COUNT(*) AS DuplicateCount
FROM dbo.FactMaintenance
GROUP BY maintenance_id
HAVING COUNT(*) > 1;
