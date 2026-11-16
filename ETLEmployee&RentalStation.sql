INSERT into DimRentalStation (
    rental_station_id,
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
    COALESCE(rs.country, 'Unknown'),
    rs.station_type
From RentalDB.dbo.RentalStation as rs
Where not exists (
    Select 1
    From DimRentalStation as d
    Where d.rental_station_id = rs.rental_station_id
);

Select * from DimRentalStation;

INSERT into DimEmployee (
    employee_id,
    first_name,
    last_name
  )
Select
   e.employee_id,
   e.first_name,
   e.last_name
From RentalDB.dbo.Employee AS e
Where NOT EXISTS (
    Select 1
    From DimEmployee AS de
    Where e.employee_id = de.employee_id
);

Select * from DimRentalStation;
Select * from dimemployee;