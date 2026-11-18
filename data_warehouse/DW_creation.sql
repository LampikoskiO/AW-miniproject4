-- Creates the data warehouse schema for the rental business domain.
-- The script drops and recreates the warehouse tables so the model is rebuilt from scratch.
-- This is a setup script and should be run only when a fresh schema is required.

--create database RentalDB;

use RentalDB;

go

-- Remove the existing fact table and dimension tables before rebuilding the schema.
drop table if exists FactRentalLine;
drop table if exists FactMaintenance;
drop table if exists DimRentalStation;
drop table if exists DimModel;
drop table if exists DimDate;
drop table if exists DimEmployee;
drop table if exists DimCustomer;
drop table if exists DimEquipment;
drop table if exists EtlLog;

-- Creating the LOG table for all ETL operations
CREATE TABLE dbo.EtlLog (
    log_id          int identity    constraint PK_EtlLog primary key,
    target_table    nvarchar(100)   not null,   -- which table was loaded
    started_at      datetime2       not null,   -- when the step started
    ended_at        datetime2       null,       -- when it finished
    rows_read       int             null,       -- rows pulled from source
    rows_loaded     int             null,       -- rows inserted into target
    rows_rejected   int             null,       -- rows skipped / failed validation
    status          nvarchar(20)    not null,   -- 'Success' or 'Failed'
    error_number    int             null,       -- ERROR_NUMBER() on failure
    error_message   nvarchar(2000)  null,       -- ERROR_MESSAGE() on failure
    run_by          nvarchar(128)   not null
        constraint DF_EtlLog_run_by default SUSER_SNAME(),  -- who ran it
    run_at          datetime2       not null
        constraint DF_EtlLog_run_at default SYSDATETIME()   -- when the row was logged
);


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

-- Equipment dimension
Create Table DimEquipment(
	equipment_key	int	identity	NOT NULL constraint PK_equipment_key primary key,
	equipment_id	int				NOT NULL,
	acquired_date	date			NOT NULL,
	removed_date	date			NOT NULL,
	condition		nvarchar(50)	NOT NULL,
	is_lost			bit				NOT NULL
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

create table FactMaintenance (
	maintenance_key			int	identity	NOT NULL constraint PK_maintenance_key primary key,
	model_key				int				not null,
	equipment_key			int				not null,
	start_date_key			int				not null,
	end_date_key			int				not null,
	maintenance_id			int				not null,
	maintenance_cost		decimal(10,2)	not null,
	maintenance_time_min	int				not null,
	maintenance_time_day	int				not null,
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
