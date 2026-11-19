USE RentalDB;

-- -- drop what all that is in the database
delete from dbo.RentalLine;
delete from dbo.Maintenance;
delete from dbo.EquipmentItem;
delete from dbo.Rental;
delete from dbo.Customer;
delete from dbo.Employee;
delete from dbo.RentalStation;
delete from dbo.Model;
delete from dbo.SubCategory;
delete from dbo.Category;
--DBCC CHECKIDENT ('dbo.RentalLine', RESEED, 0);
DBCC CHECKIDENT ('dbo.Maintenance', RESEED, 0);
DBCC CHECKIDENT ('dbo.Rental', RESEED, 0);
DBCC CHECKIDENT ('dbo.EquipmentItem', RESEED, 0);
DBCC CHECKIDENT ('dbo.Customer', RESEED, 0);
DBCC CHECKIDENT ('dbo.Employee', RESEED, 0);
DBCC CHECKIDENT ('dbo.RentalStation', RESEED, 0);
DBCC CHECKIDENT ('dbo.Model', RESEED, 0);
DBCC CHECKIDENT ('dbo.SubCategory', RESEED, 0);
DBCC CHECKIDENT ('dbo.Category', RESEED, 0);

GO
SET NOCOUNT ON;

SET XACT_ABORT ON;

BEGIN TRANSACTION;

INSERT  INTO dbo.Category (
    name
)
VALUES                    (N'Bicycle'),
                          (N'Scooter'),
                          (N'Other');

INSERT  INTO dbo.SubCategory (
    Category_id,
    name
)
VALUES                       (1, N'City bike'),
                             (1, N'E-bike'),
                             (1, N'Cargo bike'),
                             (2, N'Electric kick scooter'),
                             (2, N'Moped'),
                             (3, N'Electric skateboard');

INSERT  INTO dbo.Model (
    sub_cat_id,
    name,
    brand_name
)
VALUES                 (1, N'Esprit', N'Gazelle'),
                       (1, N'Fonk', N'Batavus'),
                       (2, N'Urban E', N'Bosch'),
                       (3, N'Family', N'Urban Arrow'),
                       (4, N'Ninebot Max', N'Segway'),
                       (4, N'KQi3', N'NIU'),
                       (5, N'NQi Sport', N'NIU'),
                       (6, N'GTR', N'Evolve');

INSERT  INTO dbo.RentalStation (
    station_name,
    address,
    city,
    country,
    station_type
)
VALUES                         (N'Berlin Central Store', N'20 Berlin Street', N'Berlin', N'Germany', N'Store'),
                               (N'Berlin Main Station', N'21 Berlin Street', N'Berlin', N'Germany', N'Station'),
                               (N'Berlin Riverside Station', N'22 Berlin Street', N'Berlin', N'Germany', N'Station'),
                               (N'Hamburg Central Store', N'23 Hamburg Street', N'Hamburg', N'Germany', N'Store'),
                               (N'Hamburg Main Station', N'24 Hamburg Street', N'Hamburg', N'Germany', N'Station'),
                               (N'Hamburg Riverside Station', N'25 Hamburg Street', N'Hamburg', N'Germany', N'Station'),
                               (N'Amsterdam Central Store', N'26 Amsterdam Street', N'Amsterdam', N'Netherlands', N'Store'),
                               (N'Amsterdam Main Station', N'27 Amsterdam Street', N'Amsterdam', N'Netherlands', N'Station'),
                               (N'Amsterdam Riverside Station', N'28 Amsterdam Street', N'Amsterdam', N'Netherlands', N'Station'),
                               (N'Rotterdam Central Store', N'29 Rotterdam Street', N'Rotterdam', N'Netherlands', N'Store'),
                               (N'Rotterdam Main Station', N'30 Rotterdam Street', N'Rotterdam', N'Netherlands', N'Station'),
                               (N'Rotterdam Riverside Station', N'31 Rotterdam Street', N'Rotterdam', N'Netherlands', N'Station'),
                               (N'Helsinki Central Store', N'32 Helsinki Street', N'Helsinki', N'Finland', N'Store'),
                               (N'Helsinki Main Station', N'33 Helsinki Street', N'Helsinki', N'Finland', N'Station'),
                               (N'Helsinki Riverside Station', N'34 Helsinki Street', N'Helsinki', N'Finland', N'Station'),
                               (N'Tampere Central Store', N'35 Tampere Street', N'Tampere', N'Finland', N'Store'),
                               (N'Tampere Main Station', N'36 Tampere Street', N'Tampere', N'Finland', N'Station'),
                               (N'Tampere Riverside Station', N'37 Tampere Street', N'Tampere', N'Finland', N'Station'),
                               (N'Stockholm Central Store', N'38 Stockholm Street', N'Stockholm', N'Sweden', N'Store'),
                               (N'Stockholm Main Station', N'39 Stockholm Street', N'Stockholm', N'Sweden', N'Station'),
                               (N'Stockholm Riverside Station', N'40 Stockholm Street', N'Stockholm', N'Sweden', N'Station');

INSERT  INTO dbo.Employee (
    first_name,
    last_name
)
VALUES                    (N'Berlin Staff', N'1'),
                          (N'Berlin Staff', N'2'),
                          (N'Berlin Staff', N'3'),
                          (N'Hamburg Staff', N'1'),
                          (N'Hamburg Staff', N'2'),
                          (N'Hamburg Staff', N'3'),
                          (N'Amsterdam Staff', N'1'),
                          (N'Amsterdam Staff', N'2'),
                          (N'Amsterdam Staff', N'3'),
                          (N'Rotterdam Staff', N'1'),
                          (N'Rotterdam Staff', N'2'),
                          (N'Rotterdam Staff', N'3'),
                          (N'Helsinki Staff', N'1'),
                          (N'Helsinki Staff', N'2'),
                          (N'Helsinki Staff', N'3'),
                          (N'Tampere Staff', N'1'),
                          (N'Tampere Staff', N'2'),
                          (N'Tampere Staff', N'3'),
                          (N'Stockholm Staff', N'1'),
                          (N'Stockholm Staff', N'2'),
                          (N'Stockholm Staff', N'3');

COMMIT TRANSACTION;