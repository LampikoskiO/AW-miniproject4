DECLARE @StartDate date, @EndDate date      --declaring startdate and enddate
DECLARE @started datetime2 = SYSDATETIME() -- for ETL logging
DECLARE @loaded int                        -- for ETL logging

SELECT @StartDate = CAST(MIN(start_date) AS date),      -- read the lowest date straight from the data 
       @EndDate   = CAST(MAX(end_date)   AS date)       -- read the highest date straight from the data
FROM dbo.RENTAL

-- LOGGING STUFF FOR THE LOG TABLE AND EXECUTING THE PROCEDURE TO BUILD DIMDATE
BEGIN TRY
    EXEC dbo.RebuildDimDate @StartDate = @StartDate, @EndDate = @EndDate                        -- execute the procedure to build dimension (DimDate)

    SET @loaded = (SELECT COUNT(*) FROM dbo.DimDate)                                            -- how many rows ended up in the dimension

    INSERT INTO dbo.EtlLog (target_table, started_at, ended_at, rows_loaded, status)            -- Inserting data into the LOG table
    VALUES ('DimDate', @started, SYSDATETIME(), @loaded, 'Success')                             -- inserting date, when it started, when it ended, how many rows were loaded, and the status of the operation which is success
END TRY
BEGIN CATCH

    INSERT INTO dbo.EtlLog (target_table, started_at, ended_at, status, error_number, error_message)        -- if it fails, we catch the error and we insert the data into the log table with the error number and error message
    VALUES ('DimDate', @started, SYSDATETIME(), 'Failed', ERROR_NUMBER(), ERROR_MESSAGE());                  -- we insert the failed status 
    
    THROW

END CATCH

SELECT COUNT(*) AS date_count FROM dbo.DimDate                  -- select all the rows in the DimDate table to see how many rows were inserted
