use RentalDB;

-- Load DimRentalStation from the source RentalStation table
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
Select * from dimemployee;