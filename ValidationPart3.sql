-- PART 3 - VALIDATION 

USE RentalDB;
GO
SET NOCOUNT ON;

-- A. Expected row counts: 3, 5, 7, 42, 12, 18, 6, 36, 44.
SELECT N'Category' AS TableName, COUNT(*) AS ActualRows, 3 AS ExpectedRows FROM dbo.Category
UNION ALL SELECT N'SubCategory', COUNT(*), 5 FROM dbo.SubCategory
UNION ALL SELECT N'Model', COUNT(*), 7 FROM dbo.Model
UNION ALL SELECT N'EquipmentItem', COUNT(*), 42 FROM dbo.EquipmentItem
UNION ALL SELECT N'RentalStation', COUNT(*), 12 FROM dbo.RentalStation
UNION ALL SELECT N'Customer', COUNT(*), 18 FROM dbo.Customer
UNION ALL SELECT N'Employee', COUNT(*), 6 FROM dbo.Employee
UNION ALL SELECT N'RENTAL', COUNT(*), 36 FROM dbo.RENTAL
UNION ALL SELECT N'RentalLine', COUNT(*), 44 FROM dbo.RentalLine;

-- B. Revenue and duration by pickup country and city.
-- Calculate per-rental amounts BEFORE grouping to avoid double-counting durations.
;WITH RentalTotals AS (
    SELECT r.rental_id, r.pickup_station_id, r.start_date,
           DATEDIFF(MINUTE, r.start_date, r.end_date) AS RentalDurationMinutes,
           SUM(rl.Price) AS RentalAmountEUR
    FROM dbo.RENTAL AS r
    JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
    GROUP BY r.rental_id, r.pickup_station_id, r.start_date, r.end_date
)
SELECT s.country, s.city, COUNT(*) AS RentalCount,
       SUM(rt.RentalAmountEUR) AS TotalRentalAmountEUR,
       SUM(rt.RentalDurationMinutes) AS TotalDurationMinutes
FROM RentalTotals AS rt
JOIN dbo.RentalStation AS s ON s.rental_station_id = rt.pickup_station_id
GROUP BY s.country, s.city
ORDER BY s.country, s.city;

-- C. Monthly rentals and revenue for time analysis / Power BI.
;WITH RentalTotals AS (
    SELECT r.rental_id, r.start_date, SUM(rl.Price) AS RentalAmountEUR
    FROM dbo.RENTAL AS r
    JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
    GROUP BY r.rental_id, r.start_date
)
SELECT CONVERT(CHAR(7), start_date, 120) AS RentalMonth,
       COUNT(*) AS RentalCount, SUM(RentalAmountEUR) AS TotalRentalAmountEUR
FROM RentalTotals
GROUP BY CONVERT(CHAR(7), start_date, 120)
ORDER BY RentalMonth;

-- D. Show which channels and payment methods were exercised.
SELECT s.station_type AS PickupChannel, r.payment_method,
       COUNT(DISTINCT r.rental_id) AS RentalCount,
       SUM(rl.Price) AS TotalRentalAmountEUR
FROM dbo.RENTAL AS r
JOIN dbo.RentalStation AS s ON s.rental_station_id = r.pickup_station_id
JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
GROUP BY s.station_type, r.payment_method
ORDER BY s.station_type, r.payment_method;

-- E. Equipment category / subcategory / model usage, good for DimEquipment.
SELECT c.name AS CategoryName, sc.name AS SubCategoryName,
       m.name AS ModelName, COUNT(*) AS RentedItems,
       SUM(rl.Price) AS TotalRentalAmountEUR
FROM dbo.RentalLine AS rl
JOIN dbo.EquipmentItem AS ei ON ei.equipment_id = rl.equipment_id
JOIN dbo.Model AS m ON m.model_id = ei.model_id
JOIN dbo.SubCategory AS sc ON sc.sub_cat_id = m.sub_cat_id
JOIN dbo.Category AS c ON c.Category_id = sc.Category_id
GROUP BY c.name, sc.name, m.name
ORDER BY c.name, sc.name, m.name;

-- F. Should return ZERO rows: no rentals without lines.
SELECT r.rental_id
FROM dbo.RENTAL AS r
LEFT JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
WHERE rl.rental_id IS NULL;

-- G. Should return ZERO rows: no end date before start date.
SELECT rental_id, start_date, end_date
FROM dbo.RENTAL
WHERE end_date <= start_date;

-- H. Should return ZERO rows: no employee on an unmanned station rental,
-- and no missing employee on a store rental.
SELECT r.rental_id, s.station_name, s.station_type, r.employee_id
FROM dbo.RENTAL AS r
JOIN dbo.RentalStation AS s ON s.rental_station_id = r.pickup_station_id
WHERE (s.station_type = N'Store' AND r.employee_id IS NULL)
   OR (s.station_type = N'Station' AND r.employee_id IS NOT NULL);

-- I. Should return ZERO rows: no double booking of a physical item.
SELECT a.equipment_id, a.rental_id AS Rental1, b.rental_id AS Rental2
FROM dbo.RentalLine AS a
JOIN dbo.RENTAL AS ra ON ra.rental_id = a.rental_id
JOIN dbo.RentalLine AS b
  ON b.equipment_id = a.equipment_id AND a.rental_id < b.rental_id
JOIN dbo.RENTAL AS rb ON rb.rental_id = b.rental_id
WHERE ra.start_date < rb.end_date AND rb.start_date < ra.end_date;
