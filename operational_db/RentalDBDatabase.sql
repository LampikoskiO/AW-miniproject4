-- part 1 make the DB

use master;
go

if db_id(N'RentalDB') is not null
begin
    alter database RentalDB set single_user with rollback immediate; -- force-close any open connections so the drop cannot be blocked
    drop database RentalDB; -- Rebuild from a clean slate when the database already exists.
end
go
Create Database RentalDB;
go

USE RentalDB;
go
	-- making all the tables below for the operational database
CREATE TABLE Category
(
	Category_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	name nvarchar(50) NOT NULL Unique
);

GO

CREATE TABLE SubCategory
(
	sub_cat_id int NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Category_id INT NOT NULL,
	name Nvarchar(50) NOT NULL,
);

CREATE TABLE Model
(
	model_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	sub_cat_id INT NOT NULL,
	name nvarchar(50) NOT NULL,
	brand_name nvarchar(50) NOT NULL,
);
go

CREATE TABLE EquipmentItem
(
	equipment_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	model_id INT NOT NULL,
	Condition nvarchar(10) NOT NULL,
	aquired_date	date	NOT NULL,
	removed_date	date	NOT NULL default('9999-12-31'),
	is_lost		binary		NOT NULL,
);
go

CREATE TABLE Maintenance(
	maintenance_id	int		identity Primary key,
	equipment_id	int,
	start_time	datetime	NOT NULL,
	end_time	datetime	NOT NULL default('9999-12-31'),
	cost	decimal(10,2)	NOT NULL,
)

CREATE TABLE RentalStation
(
	rental_station_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	station_name Nvarchar(50) NOT NULL,
	address nvarchar(100) not null,
	city nvarchar(50) not null,
	country nvarchar(50),
	station_type nvarchar(50) not null
);

CREATE TABLE Customer
(
	customer_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	first_name nvarchar(50) NOT NULL,
	last_name nvarchar(50) NOT NULL,
	address nvarchar(100) not null,
	email nvarchar(60) not null,
	phone_number nvarchar(15) not null,
	city nvarchar(50) not null,
	country nvarchar(50) not null
);
go

CREATE TABLE Employee(
	employee_id INT NOT NULL IDENtity(1,1) PRIMARY KEY,
	first_name nvarchar(50) not null,
	last_name nvarchar(50) not null
);
go


CREATE TABLE RENTAL
(
	rental_id int not null identity(1,1) PRIMARY KEY,
	customer_id int not null,
	pickup_station_id int not null,
	return_station_id INT not null,
	employee_id int null,
	start_date DATETIME not null,
	end_date DATETIME not null,
	payment_method nvarchar(30) NOT NULL
);
go

CREATE TABLE RentalLine
(
	rental_id int not null,
	rental_line_no int not null,
	equipment_id INT NOT NULL,
	Price Decimal(10,2) not null,
	VAT decimal(19, 2) not null,
	
	Constraint pk_RentalLine
	Primary KEY (rental_id, rental_line_no)
);


-- Connecting the tables to eachother with foreign keys.

-- each category has subcategories which have models and each model has a physical item
---Subcategory -> Category
Alter Table SubCategory
ADD CONSTRAINT FK_SubCategory_category
FOREIGN KEY (Category_id)
REFERENCES Category(Category_id),
UNIQUE(Category_id, name)

-- Model -> Subcategory
Alter Table Model
ADD CONSTRAINT FK_Model_SubCategory
FOREIGN KEY (sub_cat_id)
REFERENCES SubCategory(sub_cat_id)

--equipmentItem -> Model
ALTER Table EquipmentItem
ADD CONSTRAINT FK_EquipmentItem_Model
FOREIGN KEY (model_id)
REFERENCES Model(model_id)

ALTER Table Maintenance
ADD CONSTRAINT FK_equipment_id
foreign key (equipment_id)
references EquipmentItem(equipment_id)


---- Rental -> Customer
-- every rental belongs to a customer
Alter Table Rental
ADD CONSTRAINT FK_Rental_Customer
FOREIGN KEY (Customer_id)
REFERENCES Customer(customer_id)
go

-- Rental --> Pickup station
-- pickupstation needs to actually exist
ALTER table rental
add CONSTRAINT FK_Rental_PickStation
FOREIGN KEY (pickup_station_id)
REFERENCES RentalStation(rental_station_id)

-->Rental --> return station
--returnstation needs to actually exist
ALTER TABLE rental
ADD CONSTRAINT FK_Rental_ReturnStation
FOREIGN KEY (return_station_id)
REFERENCES RentalStation(rental_station_id)

--Rental -> Employee
--can be null since employee is  not always present for rentals
ALTER TABLE RENTAL
ADD CONSTRAINT FK_Rental_Employee
FOREIGN KEY (employee_id)
REFERENCES Employee(employee_id)
go

--Rentalline --> Rental
--every rentalline (order) has a rental_id
Alter Table Rentalline
ADD Constraint FK_RentalLine_rental
FOREIGN KEY (rental_id)
REFERENCES Rental(rental_id)

--RentalLine.equipment_id → EquipmentItem
--every row needs to have a physical item that is being rented
Alter table Rentalline
ADD CONSTRAINT FK_RentalLine_EquipmentItem
FOREIGN KEY (equipment_id)
REFERENCES EquipmentItem(equipment_id)
