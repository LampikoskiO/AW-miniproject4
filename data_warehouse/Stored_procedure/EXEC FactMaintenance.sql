EXEC dbo.usp_LoadFactMaintenance

SELECT COUNT(*) AS Datawarehouse_Count FROM FactMaintenance
SELECT COUNT(*) AS SourceDB_Count FROM Maintenance
SELECT * FROM dbo.EtlLog -- checking that logging works
