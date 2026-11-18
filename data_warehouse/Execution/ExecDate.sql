DECLARE @StartDate date, @EndDate date      --declaring startdate and enddate

SELECT @StartDate = CAST(MIN(start_date) AS date),      -- read the lowest date straight from the data
       @EndDate   = CAST(MAX(end_date)   AS date)       -- read the highest date straight from the data
FROM dbo.RENTAL

EXEC dbo.RebuildDimDate @StartDate = @StartDate, @EndDate = @EndDate                        -- execute the procedure to build dimension (DimDate)

SELECT COUNT(*) AS date_count FROM dbo.DimDate                  -- select all the rows in the DimDate table to see how many rows were inserted
