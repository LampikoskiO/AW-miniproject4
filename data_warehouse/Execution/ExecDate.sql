-- Fixed date window, now its wide enough to cover every rental and maintenance date even in the future
DECLARE @StartDate date = '2024-01-01';   -- before our earliest data !!! PROBLEM IS THAT THIS IS HARDCODED !!!
DECLARE @EndDate   date = '2027-12-31';   -- after our latest data !!! PROBLEM IS THAT THIS IS HARDCODED !!!

EXEC dbo.RebuildDimDate @StartDate = @StartDate, @EndDate = @EndDate   -- build DimDate for this range (the procedure logs to EtlLog itself)

SELECT COUNT(*) AS date_count FROM dbo.DimDate                         -- check how many rows are in DimDate
