use RentalDB;
go

-- insert into FactRentalLine
select r.rental_id, rental_line_no, customer_key, employee_key, model_key,
	CONVERT(int, CONVERT(char(8), start_Date, 112)) as start_date_key, 
	CONVERT(int, CONVERT(char(8), end_date, 112)) as end_date_key,
	drs1.rental_station_key as pickup_station_key, 
	drs2.rental_station_key as return_station_key, 
	price,
	0 as VAT, -- change that !
	start_date as datetime_start, end_date as datetime_end, 
	payment_method,
	(DATEDIFF(MINUTE, start_date, end_date)) as rental_time_minutes
from Rental as r
inner join RentalLine as rl
on r.rental_id = rl.rental_id
inner join customer as c
on c.customer_id = r.customer_id
inner join DimCustomer as dc
on c.customer_id = dc.customer_id
full join Employee as e
on e.employee_id = r.employee_id
inner join DimEmployee as de
on e.employee_id = de.employee_id
inner join RentalStation as rs1
on rs1.rental_station_id = r.pickup_station_id
inner join DimRentalStation as drs1
on drs1.rental_station_id = rs1.rental_station_id
inner join RentalStation as rs2
on rs2.rental_station_id = r.return_station_id
inner join DimRentalStation as drs2
on drs2.rental_station_id = rs2.rental_station_id
inner join EquipmentItem as ei
on ei.equipment_id = rl.equipment_id
inner join Model as m
on m.model_id = ei.model_id
inner join DimModel as dm
on dm.model_id = m.model_id;
go
