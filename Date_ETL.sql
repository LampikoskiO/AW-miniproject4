USE RentalDB
GO

SET LANGUAGE us_english

INSERT INTO dbo.DimDate ([date], [day], [month], month_name, [year])
SELECT date,
       DAY(d),
       MONTH(d),
       DATENAME(month, d),
       YEAR(d)
FROM (
    SELECT CAST(start_date AS date) AS d FROM dbo.RENTAL --changing it from datetime to date with CAST
    UNION 
    SELECT CAST(end_date AS date)        FROM dbo.RENTAL --changing it from datetime to date with CAST
) AS dates

SELECT COUNT(*) AS date_count FROM dbo.DimDate