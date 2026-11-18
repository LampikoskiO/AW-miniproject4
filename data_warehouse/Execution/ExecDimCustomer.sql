--Execute the stored procedure
EXEC dbo.LoadDimCustomer;

-- Control the result
SELECT COUNT(*) AS TotalCustomers
FROM dbo.DimCustomer;

SELECT *
FROM dbo.DimCustomer;

--Checking the ETL-loggen
SELECT *
FROM dbo.EtlLog
WHERE target_table = 'DimCustomer'
ORDER BY started_at DESC;

-- Run the procedure below to control it doesn´t create duplicates
EXEC dbo.LoadDimCustomer;

--Data validation queries to compare totals db and dw
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
