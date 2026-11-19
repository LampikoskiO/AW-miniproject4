USE RentalDB
GO

CREATE OR ALTER PROCEDURE dbo.RebuildDimDate
    @StartDate date,
    @EndDate   date
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @started datetime2 = SYSDATETIME()  -- for ETL logging
    DECLARE @loaded int = 0                     -- for ETL logging

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

        SET @loaded = (SELECT COUNT(*) FROM dbo.DimDate)   -- how many rows ended up in the dimension

        COMMIT TRANSACTION

        -- Log successful execution
        INSERT INTO dbo.EtlLog (target_table, started_at, ended_at, rows_loaded, status)
        VALUES ('DimDate', @started, SYSDATETIME(), @loaded, 'Success')
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION

        -- Log failed execution
        INSERT INTO dbo.EtlLog (target_table, started_at, ended_at, status, error_number, error_message)
        VALUES ('DimDate', @started, SYSDATETIME(), 'Failed', ERROR_NUMBER(), ERROR_MESSAGE());

        THROW
    END CATCH
END
GO


-- run this after the FactMaintenance procedure if it doesn't work
DECLARE @StartDate date;
DECLARE @EndDate date;

SELECT
    @StartDate = MIN(event_date),
    @EndDate = MAX(event_date)
FROM (
    SELECT CAST(start_time AS date) AS event_date
    FROM dbo.Maintenance
    WHERE start_time IS NOT NULL

    UNION ALL

    SELECT CAST(end_time AS date)
    FROM dbo.Maintenance
    WHERE end_time IS NOT NULL
      AND CAST(end_time AS date) <> '9999-12-31'
) AS dates;

IF @StartDate IS NOT NULL
    EXEC dbo.RebuildDimDate
        @StartDate = @StartDate,
        @EndDate = @EndDate;
