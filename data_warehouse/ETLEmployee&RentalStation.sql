use RentalDB;
GO
/*-- Load DimRentalStation from the source RentalStation table
INSERT into DimRentalStation (
    rental_station_id,          -- business key from the source
    station_name,
    address,
    city,
    country,
    station_type)
Select
    rs.rental_station_id,
    rs.station_name,
    rs.address,
    rs.city,
    COALESCE(rs.country, 'Unknown'),        -- if country is NULL, store 'Unknown' instead
    rs.station_type
From RentalDB.dbo.RentalStation as rs
Where not exists (                          -- only insert stations not already in the dimension
    Select 1
    From DimRentalStation as d
    Where d.rental_station_id = rs.rental_station_id    -- match on the business key
);

Select * from DimRentalStation; -- check the loaded rows

INSERT into DimEmployee (
    employee_id,                -- business key from the source
    first_name,
    last_name
  )
Select
   e.employee_id,
   e.first_name,
   e.last_name
From RentalDB.dbo.Employee AS e
Where NOT EXISTS (                  -- only insert employees not already in the dimension
    Select 1
    From DimEmployee AS de  
    Where e.employee_id = de.employee_id        -- match on the business key
);

-- check both dimensions
Select * from DimRentalStation;
Select * from dimemployee;*/

----------------- ETL Employee

CREATE OR ALTER PROCEDURE dbo.LoadDimEmployee
as
begin
    set nocount on;
    set xact_abort on;

DECLARE @started_at datetime2 = sysdatetime();
DECLARE @loaded INT = 0;
DECLARE @rows_read INT = 0;

BEGIN try
BEGIN transaction

Select @rows_read = count(*)       --im counting rows in source table
from dbo.Employee

Update d -- updating employees if the names have changed
Set d.first_name = e.first_name, d.last_name = e.last_name
from dbo.DimEmployee as d
join dbo.Employee as e
on d.employee_id = e.employee_id
Where exists (
select d.first_name, d.last_name
except 
select e.first_name, e.last_name
);

SET @loaded = @loaded + @@ROWCOUNT;

Insert into DimEmployee   --- inserting new employees
(employee_id, first_name, last_name)
Select e.employee_id, e.first_name, e.last_name
From dbo.Employee as e
Where not exists (
Select 1 from DimEmployee as d
Where d.employee_id = e.employee_id);

SET @loaded = @loaded + @@ROWCOUNT;
Insert into dbo.etllog
(target_table, started_at, ended_at, rows_read, rows_loaded, rows_rejected, status)
Values ('DimEmployee', @started_at, SYSDATETIME(), @rows_read, @loaded, 0, 'success');

COMMIT TRANSACTION;
End try

Begin catch
Declare @error_number int = error_number()
Declare @error_message nvarchar(500) = error_message();

IF xact_state() <> 0 -- if something fails
rollback transaction;

Insert into dbo.etllog -- loggin failed etl
(target_table, started_at, ended_at, rows_read, 
rows_loaded, rows_rejected, status, error_number, error_message)
Values ('DimEmployee', @started_at, sysdatetime(), @rows_read, 
0, null, 'failed', @error_number, @error_message);

THROW;

End catch;
END;
go


-- ETL RentalStation
CREATE OR ALTER PROCEDURE dbo.LoadDimRentalStation
as
begin
    set nocount on;
    set xact_abort on;

DECLARE @started_at datetime2 = sysdatetime();
DECLARE @loaded INT = 0;
DECLARE @rows_read INT = 0;

BEGIN try
BEGIN transaction

Select @rows_read = count(*)       --im counting rows in table
from dbo.RentalStation

Update d 
Set d.station_name = rs.station_name, 
d.address = rs.address,
d.city = rs.city,
d.country = coalesce(rs.country, 'unkown'),
d.station_type = rs.station_type
From dbo.RentalStation as d
join DimRentalStation as rs
on d.rental_station_id = rs.rental_station_id
WHERE exists (
SELECT d.station_name, d.address, d.city, d.country, d.station_type
EXCEPT
select rs.station_name, rs.address, rs.city, coalesce(rs.country, 'unkonwn'), rs.station_type);

SET @loaded = @loaded + @@ROWCOUNT

Insert into DimRentalStation 
(rental_station_id, station_name, address, city, country, station_type)
SELECT rs.rental_station_id, rs.station_name, rs.address, rs.city, coalesce(rs.country, 'unkown'), rs.station_type
FROM dbo.RentalStation as rs
Where not exists (
select 1 from DimRentalStation as d
where d.rental_station_id = rs.rental_station_id
);

Set @loaded = @loaded + @@ROWCOUNT

Insert into dbo.etllog
(target_table, started_at, ended_at, rows_read, rows_loaded, rows_rejected, status)
Values ('DimRentalStation', @started_at, sysdatetime(), @rows_read, @loaded, 0, 'success');

Commit transaction

End try

Begin catch

Declare @error_number int = error_number()
declare @error_message nvarchar(500) = error_message()

if xact_state() <> 0
rollback transaction;

-- logging failed etl
Insert into dbo.etllog 
(target_table, started_at, ended_at, rows_read, rows_loaded, rows_rejected, status, error_number, error_message)
Values ('DimRentalStation', @started_at, sysdatetime(), @rows_read, 0, null, 'failed', @error_number, @error_message);
Throw;

End catch;
End;
go

exec dbo.LoadDimEmployee
exec dbo.LoadDimRentalStation

Select * from dbo.etllog order by log_id 
