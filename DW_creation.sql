-- use database

create table DimRentalStation (
	rental_station_key	int			constraint PK_rental_station_key Primary key,
	rental_station_id	int	not null,
	station_name	nvarchar(50)	not null,
	address			nvarchar(100)	not null,
	city			nvarchar(50)	not null,
	country			nvarchar(50)	not null,
	station_type	nvarchar(10)	not null,
)

create table DimModel (
	model_key			int			constraint PK_model_key	primary key,
	model_id			int	not null,
	brand_name			nvarchar(50)	not null,
	model_name			nvarchar(50)	not null,
	subcategory_name	nvarchar(50)	not null,
	category_name		nvarchar(50)	not null
)

create table DimCustomer (
	customer_key		int			constraint PK_customer_key primary key,
	first_name		nvarchar(20)	not null,
	last_name		nvarchar(20)	not null,
	address			nvarchar(100)	not null,
	city			nvarchar(50)	not null,
	country			nvarchar(50)	not null,
	email			nvarchar(60)	not null,
	phone_number	nvarchar(12)	not null,
)

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

create table FactRentalLine (
	rental_line_key		int			constraint PK_customer_key primary key,
	customer_key		int	not null,
	employee_key		int		null,
	model_key			int	not null,
	start_date_key		int	not null,
	end_date_key		int	not null,
	pickup_station_key	int	not null,
	return_station_key	int	not null,
	price		decimal(10,2)	not null,
	-- VAT			decimal(10,2)	not null, -- add to database ?
	datetime_start	datetime	not null,
	datetime_end	datetime	not null,
	rental_time_minutes	int		not null,
)


