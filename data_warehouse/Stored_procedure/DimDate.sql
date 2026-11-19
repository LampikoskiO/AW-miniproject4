USE RentalDB
GO

CREATE OR ALTER PROCEDURE dbo.RebuildDimDate
    @StartDate date,
    @EndDate   date
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    -- Validate input parameters
    IF @StartDate IS NULL OR @EndDate IS NULL
        THROW 51101, 'Start_date & End_date are both required.', 1

    IF @EndDate < @StartDate
        THROW 51102, 'End_date must not be before Start_date.', 1

    SET LANGUAGE us_english

    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @CurrentDate date = @StartDate

        -- Loop through the complete date range
        WHILE @CurrentDate <= @EndDate
        BEGIN
            -- Insert only dates that do not already exist
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.DimDate
                WHERE date_key = CONVERT(int, CONVERT(char(8), @CurrentDate, 112))
            )
            BEGIN
                INSERT INTO dbo.DimDate
                    (date_key, [date], [day], [month], month_name, [year])
                VALUES (
                    CONVERT(int, CONVERT(char(8), @CurrentDate, 112)),
                    @CurrentDate,
                    DAY(@CurrentDate),
                    MONTH(@CurrentDate),
                    DATENAME(month, @CurrentDate),
                    YEAR(@CurrentDate)
                )
            END

            -- Move to the next calendar day
            SET @CurrentDate = DATEADD(day, 1, @CurrentDate)
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
DECLARE @StartDate date, @EndDate date;

SELECT
    @StartDate = MIN(DateValue),
    @EndDate = MAX(DateValue)
FROM (
    SELECT CAST(start_date AS date) AS DateValue FROM dbo.Rental
    UNION ALL
    SELECT CAST(end_date AS date) FROM dbo.Rental
    UNION ALL
    SELECT CAST(start_time AS date) FROM dbo.Maintenance
    WHERE start_time IS NOT NULL
    UNION ALL
    SELECT CAST(end_time AS date) FROM dbo.Maintenance
    WHERE end_time IS NOT NULL
) AS AllDates;



