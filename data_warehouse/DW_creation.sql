-- Creates the data warehouse schema for the rental business domain.
-- The script drops and recreates the warehouse tables so the model is rebuilt from scratch.
-- This is a setup script and should be run only when a fresh schema is required.

--create database RentalDB;

use RentalDB;

go

-- Remove the existing fact table and dimension tables before rebuilding the schema.
drop table FactRentalLine;
drop table DimRentalStation;
drop table DimModel;
drop table DimDate;
drop table DimEmployee;
drop table DimCustomer;

-- Rental station dimension: stores static information about each rental station.
create table DimRentalStation (
	rental_station_key	int identity	constraint PK_rental_station_key Primary key,
	rental_station_id	int	not null,
	station_name	nvarchar(50)	not null,
	address			nvarchar(100)	not null,
	city			nvarchar(50)	not null,
	country			nvarchar(50)	not null,
	station_type	nvarchar(50)	not null,
);

-- Vehicle model dimension: describes each model and the product hierarchy.
create table DimModel (
	model_key			int identity	constraint PK_model_key	primary key,
	model_id			int	not null,
	brand_name			nvarchar(50)	not null,
	model_name			nvarchar(50)	not null,
	subcategory_name	nvarchar(50)	not null,
	category_name		nvarchar(50)	not null
);

-- Customer dimension: contains the master data for all customers.
create table DimCustomer (
	customer_key		int	identity	constraint PK_customer_key primary key,
	customer_id			int			not null,
	first_name		nvarchar(50)	not null,
	last_name		nvarchar(50)	not null,
	address			nvarchar(100)	not null,
	city			nvarchar(50)	not null,
	country			nvarchar(50)	not null,
	email			nvarchar(60)	not null,
	phone_number	nvarchar(15)	not null,
);

-- Employee dimension: tracks the employees involved in rentals.
create table DimEmployee (
	Employee_key	int	identity	NOT NULL constraint PK_employee_key primary key,
	employee_id		int				NOT NULL,
	first_name		nvarchar(50)	NOT NULL,
	last_name		nvarchar(50)	NOT NULL
);

-- Date dimension: provides calendar attributes used for time analysis and reporting.
create table DimDate (
	date_key		int 			NOT NULL constraint PK_date_key primary key,
	date			date			NOT NULL,
	day				int				NOT NULL,
	month			int				NOT NULL,
	month_name		nvarchar(50)	NOT NULL,
	year			int				NOT NULL
);

-- Fact table: stores each rental line as a transactional fact record.
-- It links to dimensions for customer, employee, vehicle model, dates, and stations.
create table FactRentalLine (
	rental_id		int,
	rental_line_no	int,
	customer_key		int	not null,
	employee_key		int		null,
	model_key			int	not null,
	start_date_key		int	not null,
	end_date_key		int	not null,
	pickup_station_key	int	not null,
	return_station_key	int	not null,
	price		decimal(10,2)	not null,
	VAT			decimal(10,2)	not null,
	datetime_start	datetime	not null,
	datetime_end	datetime	not null,
	payment_method  nvarchar(50) not null,
	rental_time_minutes	int		not null,
	constraint  PK_rentaline_id primary key (rental_id, rental_line_no)
);

-- Add the foreign key constraints that connect each fact record to its dimension tables.
-- These relationships enable analytical queries across customer, time, station, and model data.
alter table FactRentalLine
add constraint	FK_customer_key foreign key (customer_key) references DimCustomer(customer_key),
	constraint	FK_employee_key foreign key (employee_key) references DimEmployee(employee_key),
	constraint	FK_model_key foreign key (model_key) references DimModel(model_key),
	constraint	FK_start_date_key foreign key (start_date_key) references DimDate(date_key),
	constraint	FK_end_date_key foreign key (end_date_key) references DimDate(date_key),
	constraint	FK_pickup_station_key foreign key (pickup_station_key) references DimRentalStation(rental_station_key),
	constraint	FK_return_station_key foreign key (return_station_key) references DimRentalStation(rental_station_key);
