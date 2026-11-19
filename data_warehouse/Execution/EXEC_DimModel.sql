-- Stored procedure execution for dimmodel
exec dbo.usp_load_dimModel;

--View the loaded data
SELECT * FROM dbo.DimModel;

--Check the ETL log:
SELECT * FROM dbo.ETLLog WHERE target_table = 'usp_load_dimModel';

