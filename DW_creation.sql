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
	payment_method  nvarchar(50) not null,
	rental_time_minutes	int		not null,
);

alter table FactRentalLine
add constraint	FK_customer_key foreign key (customer_key) references DimCustomer(customer_key),
	constraint	FK_employee_key foreign key (employee_key) references DimEmployee(employee_key),
	constraint	FK_model_key foreign key (model_key) references DimModel(model_key),
	constraint	FK_start_date_key foreign key (start_date_key) references DimDate(date_key),
	constraint	FK_end_date_key foreign key (end_date_key) references DimDate(date_key),
	constraint	FK_pickup_station_key foreign key (pickup_station_key) references DimRentalStation(rental_station_key),
	constraint	FK_return_station_key foreign key (return_station_key) references DimRentalStation(rental_station_key);
