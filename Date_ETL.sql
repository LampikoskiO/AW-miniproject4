/*
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

*/

-- Better way to do this, according to labs 2.1C and lab 2.1B
USE RentalDB
GO

CREATE OR ALTER PROCEDURE dbo.RebuildDimDate
    @StartDate date,
    @EndDate   date
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    IF @StartDate IS NULL OR @EndDate IS NULL
        THROW 51101, 'Start_date & End_date are both required.', 1
    IF @EndDate < @StartDate
        THROW 51102, 'End_date must not be before Start_date.', 1

    SET LANGUAGE us_english

    BEGIN TRY
        BEGIN TRANSACTION

        DELETE FROM dbo.DimDate

        DECLARE @CurrentDate date = @StartDate
        WHILE @CurrentDate <= @EndDate                                              -- we loop through all the dates in the date range and fill them into the table
        BEGIN
            INSERT INTO dbo.DimDate ([date], [day], [month], month_name, [year])
            VALUES (
                @CurrentDate,
                DAY(@CurrentDate),
                MONTH(@CurrentDate),
                DATENAME(month, @CurrentDate),
                YEAR(@CurrentDate)
            )

            SET @CurrentDate = DATEADD(day, 1, @CurrentDate) -- change the day
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
GO

EXEC dbo.RebuildDimDate @StartDate = '20260801', @EndDate = '20261031'
SELECT COUNT(*) AS date_count FROM dbo.DimDate