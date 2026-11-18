-- PART 3 - VALIDATION
-- Checks the seeded source data: row counts, totals, and integrity rules.

USE RentalDB;
GO
SET NOCOUNT ON;

-- A. Compare actual row counts against the expected counts for each table.
--    ActualRows should equal ExpectedRows on every row.
SELECT N'Category' AS TableName, COUNT(*) AS ActualRows, 3 AS ExpectedRows FROM dbo.Category
UNION ALL SELECT N'SubCategory', COUNT(*), 5 FROM dbo.SubCategory
UNION ALL SELECT N'Model', COUNT(*), 7 FROM dbo.Model
UNION ALL SELECT N'EquipmentItem', COUNT(*), 42 FROM dbo.EquipmentItem
UNION ALL SELECT N'Maintenance', COUNT(*), 21 FROM dbo.Maintenance
UNION ALL SELECT N'RentalStation', COUNT(*), 12 FROM dbo.RentalStation
UNION ALL SELECT N'Customer', COUNT(*), 18 FROM dbo.Customer
UNION ALL SELECT N'Employee', COUNT(*), 6 FROM dbo.Employee
UNION ALL SELECT N'RENTAL', COUNT(*), 36 FROM dbo.RENTAL
UNION ALL SELECT N'RentalLine', COUNT(*), 44 FROM dbo.RentalLine;

-- B. Revenue and duration grouped by the pickup station's country and city.
-- The CTE totals each rental ONCE first, so joining its many lines does not
-- multiply the duration. Then the outer query groups those per-rental totals.
;WITH RentalTotals AS (
    SELECT r.rental_id, r.pickup_station_id, r.start_date,
           DATEDIFF(MINUTE, r.start_date, r.end_date) AS RentalDurationMinutes,  -- length of the rental
           SUM(rl.Price) AS RentalAmountEUR                                      -- sum of its lines
    FROM dbo.RENTAL AS r
    JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
    GROUP BY r.rental_id, r.pickup_station_id, r.start_date, r.end_date          -- one row per rental
)
SELECT s.country, s.city, COUNT(*) AS RentalCount,
       SUM(rt.RentalAmountEUR) AS TotalRentalAmountEUR,
       SUM(rt.RentalDurationMinutes) AS TotalDurationMinutes
FROM RentalTotals AS rt
JOIN dbo.RentalStation AS s ON s.rental_station_id = rt.pickup_station_id        -- look up the pickup station
GROUP BY s.country, s.city
ORDER BY s.country, s.city;

-- C. Rentals and revenue per month, for time analysis / Power BI.
-- Again total each rental once in the CTE, then group by month.
;WITH RentalTotals AS (
    SELECT r.rental_id, r.start_date, SUM(rl.Price) AS RentalAmountEUR
    FROM dbo.RENTAL AS r
    JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
    GROUP BY r.rental_id, r.start_date
)
SELECT CONVERT(CHAR(7), start_date, 120) AS RentalMonth,   -- style 120 gives 'YYYY-MM-...', CHAR(7) keeps 'YYYY-MM'
       COUNT(*) AS RentalCount, SUM(RentalAmountEUR) AS TotalRentalAmountEUR
FROM RentalTotals
GROUP BY CONVERT(CHAR(7), start_date, 120)
ORDER BY RentalMonth;

-- D. Which sales channels (store vs station) and payment methods were used.
-- COUNT(DISTINCT rental_id) so a multi-line rental is still counted once.
SELECT s.station_type AS PickupChannel, r.payment_method,
       COUNT(DISTINCT r.rental_id) AS RentalCount,
       SUM(rl.Price) AS TotalRentalAmountEUR
FROM dbo.RENTAL AS r
JOIN dbo.RentalStation AS s ON s.rental_station_id = r.pickup_station_id
JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
GROUP BY s.station_type, r.payment_method
ORDER BY s.station_type, r.payment_method;

-- E. Usage by category / subcategory / model. Walks the product hierarchy
-- up from each rented line. Useful later for a DimEquipment dimension.
SELECT c.name AS CategoryName, sc.name AS SubCategoryName,
       m.name AS ModelName, COUNT(*) AS RentedItems,
       SUM(rl.Price) AS TotalRentalAmountEUR
FROM dbo.RentalLine AS rl
JOIN dbo.EquipmentItem AS ei ON ei.equipment_id = rl.equipment_id   -- line -> physical item
JOIN dbo.Model AS m ON m.model_id = ei.model_id                     -- item -> model
JOIN dbo.SubCategory AS sc ON sc.sub_cat_id = m.sub_cat_id          -- model -> subcategory
JOIN dbo.Category AS c ON c.Category_id = sc.Category_id            -- subcategory -> category
GROUP BY c.name, sc.name, m.name
ORDER BY c.name, sc.name, m.name;

-- F. Integrity check: every rental must have at least one line.
-- LEFT JOIN then keep only unmatched rentals. Should return ZERO rows.
SELECT r.rental_id
FROM dbo.RENTAL AS r
LEFT JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
WHERE rl.rental_id IS NULL;

-- G. Integrity check: end date must be after start date. Should return ZERO rows.
SELECT rental_id, start_date, end_date
FROM dbo.RENTAL
WHERE end_date <= start_date;

-- H. Integrity check on the staffing rule: a store rental must have an employee,
-- a station (unmanned) rental must not. Should return ZERO rows.
SELECT r.rental_id, s.station_name, s.station_type, r.employee_id
FROM dbo.RENTAL AS r
JOIN dbo.RentalStation AS s ON s.rental_station_id = r.pickup_station_id
WHERE (s.station_type = N'Store' AND r.employee_id IS NULL)        -- store with no employee = wrong
   OR (s.station_type = N'Station' AND r.employee_id IS NOT NULL); -- station with an employee = wrong

-- I. Integrity check: the same physical item cannot be rented twice at
-- overlapping times (double booking). Should return ZERO rows.
-- Pairs each line with another line for the same equipment (a.rental_id < b.rental_id
-- avoids matching a row with itself or listing the same pair twice),
-- then keeps only pairs whose rental time ranges overlap.
SELECT a.equipment_id, a.rental_id AS Rental1, b.rental_id AS Rental2
FROM dbo.RentalLine AS a
JOIN dbo.RENTAL AS ra ON ra.rental_id = a.rental_id
JOIN dbo.RentalLine AS b
  ON b.equipment_id = a.equipment_id AND a.rental_id < b.rental_id
JOIN dbo.RENTAL AS rb ON rb.rental_id = b.rental_id
WHERE ra.start_date < rb.end_date AND rb.start_date < ra.end_date;  -- the overlap test

-- J. Equipment lifecycle dates must be valid. Should return ZERO rows.
SELECT equipment_id, aquired_date, removed_date, is_lost
FROM dbo.EquipmentItem
WHERE removed_date < aquired_date
   OR is_lost NOT IN (0x00, 0x01);

-- K. Maintenance periods must have a positive duration and nonnegative cost.
-- Should return ZERO rows.
SELECT maintenance_id, equipment_id, start_time, end_time, cost
FROM dbo.Maintenance
WHERE end_time <= start_time
   OR cost < 0;

-- L. Rentals may only use equipment that was acquired, not yet removed, and
-- not marked lost. Equipment must also be out of maintenance for the full
-- rental interval. Should return ZERO rows.
SELECT r.rental_id, rl.rental_line_no, ei.equipment_id,
       r.start_date, r.end_date
FROM dbo.RENTAL AS r
JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
JOIN dbo.EquipmentItem AS ei ON ei.equipment_id = rl.equipment_id
WHERE ei.aquired_date > CONVERT(date, r.start_date)
   OR ei.removed_date < CONVERT(date, r.end_date)
   OR ei.is_lost <> 0x00
   OR EXISTS (
       SELECT 1
       FROM dbo.Maintenance AS m
       WHERE m.equipment_id = ei.equipment_id
         AND m.start_time < r.end_date
         AND r.start_date < m.end_time
   );
