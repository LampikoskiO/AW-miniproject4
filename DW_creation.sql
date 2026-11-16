-- use database

create table DimRentalStation (
	rental_station_key	int,
	rental_station_id	int
)

create table DimModel ()

create table DimCustomer ()

create table DimEmployee (
Employee_key	int				NOT NULL constraint PK_employee_key primary key,
employee_id		int				NOT NULL,
first_name		nvarchar(50)	NOT NULL,
last_name		nvarchar(50)	NOT NULL
);

create table DimDate (
date_key		int				NOT NULL constraint PK_date_ket primary key,
date			date			NOT NULL,
day				int				NOT NULL,
month			int				NOT NULL,
month_name		nvarchar(50)	NOT NULL,
year			int				NOT NULL
);

create table FactRentalLine ()
