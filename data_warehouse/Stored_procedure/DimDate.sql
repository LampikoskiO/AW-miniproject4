-- BEST way to do this, according to labs 2.1C and lab 2.1B, its reusable, has validation and makes no gaps in the calendar.
USE RentalDB
GO

CREATE OR ALTER PROCEDURE dbo.RebuildDimDate        -- procedure to build/rebuild the dimdate tables in data warehouse
    @StartDate date,                            -- declaring startdate and enddate as input parameters for the procedure
    @EndDate   date
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    IF @StartDate IS NULL OR @EndDate IS NULL
        THROW 51101, 'Start_date & End_date are both required.', 1 -- we validate the input parameters, if they are null we throw an error
    IF @EndDate < @StartDate
        THROW 51102, 'End_date must not be before Start_date.', 1

    SET LANGUAGE us_english

    BEGIN TRY
        BEGIN TRANSACTION       -- transaction makes it so its all or nothing, if something fails it will roll back the changes and not leave the table half filled

        DELETE FROM dbo.DimDate -- delete all the rows in the dimdate table, we are going to rebuild it from scratch

        DECLARE @CurrentDate date = @StartDate
        WHILE @CurrentDate <= @EndDate                                              -- we loop through all the dates in the date range and fill them into the table
        BEGIN                                                                                       -- this also doesnt leave any gaps in the calendar
            INSERT INTO dbo.DimDate (date_key, [date], [day], [month], month_name, [year]) 
            VALUES (
                CONVERT(int, CONVERT(char(8), @CurrentDate, 112)),   -- 8 digit number YYYYMMDD key
                @CurrentDate,
                DAY(@CurrentDate),
                MONTH(@CurrentDate),
                DATENAME(month, @CurrentDate),
                YEAR(@CurrentDate)
            )

            SET @CurrentDate = DATEADD(day, 1, @CurrentDate) -- change the day to the next one and start loop again
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
