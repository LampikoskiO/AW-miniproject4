-- PART 3 - TEST DATA

USE RentalDB;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Protect existing work. The script is intentionally one-time seed data.
    IF EXISTS (SELECT 1 FROM dbo.Category)
       OR EXISTS (SELECT 1 FROM dbo.SubCategory)
       OR EXISTS (SELECT 1 FROM dbo.Model)
       OR EXISTS (SELECT 1 FROM dbo.EquipmentItem)
       OR EXISTS (SELECT 1 FROM dbo.RentalStation)
       OR EXISTS (SELECT 1 FROM dbo.Customer)
       OR EXISTS (SELECT 1 FROM dbo.Employee)
       OR EXISTS (SELECT 1 FROM dbo.RENTAL)
       OR EXISTS (SELECT 1 FROM dbo.RentalLine)
    BEGIN
        THROW 51000, 'RentalDB tables are not empty. Seed cancelled to avoid duplicates.', 1;
    END;

    -- 1. Master data: Category -> SubCategory -> Model -> EquipmentItem.
    INSERT INTO dbo.Category (name)
    VALUES
    (N'Bicycle'),
    (N'Scooter'),
    (N'Kickboard');

    INSERT INTO dbo.SubCategory (Category_id, name)
    SELECT c.Category_id, d.SubCategoryName
    FROM (VALUES
    (N'Bicycle', N'City e-bike'),
    (N'Bicycle', N'Cargo e-bike'),
    (N'Scooter', N'Electric moped'),
    (N'Scooter', N'Seated e-scooter'),
    (N'Kickboard', N'Standing e-kickboard')
    ) AS d(CategoryName, SubCategoryName)
    JOIN dbo.Category AS c ON c.name = d.CategoryName;

    INSERT INTO dbo.Model (sub_cat_id, name, brand_name)
    SELECT sc.sub_cat_id, d.ModelName, d.BrandName
    FROM (VALUES
    (N'Bicycle', N'City e-bike', N'CityRide 3', N'UrbanMotion'),
    (N'Bicycle', N'City e-bike', N'Metro E2', N'VoltWay'),
    (N'Bicycle', N'Cargo e-bike', N'CargoFlow 2', N'GreenHaul'),
    (N'Scooter', N'Electric moped', N'GoMoped 50', N'MoveTech'),
    (N'Scooter', N'Seated e-scooter', N'SitGo X', N'Electra'),
    (N'Kickboard', N'Standing e-kickboard', N'Swift K2', N'ZipRide'),
    (N'Kickboard', N'Standing e-kickboard', N'Urban Glide', N'FlowWheel')
    ) AS d(CategoryName, SubCategoryName, ModelName, BrandName)
    JOIN dbo.Category AS c ON c.name = d.CategoryName
    JOIN dbo.SubCategory AS sc
        ON sc.Category_id = c.Category_id AND sc.name = d.SubCategoryName;

    -- Six physical units of each model: 7 models x 6 cities = 42 items.
    -- The lowest equipment_id for a model is city slot 1, and so on.
    INSERT INTO dbo.EquipmentItem (model_id, [Condition])
    SELECT m.model_id, d.ItemCondition
    FROM dbo.Model AS m
    CROSS JOIN (VALUES
        (1, N'Excellent'), (2, N'Good'), (3, N'Good'),
        (4, N'Excellent'), (5, N'Fair'), (6, N'Good')
    ) AS d(CitySlot, ItemCondition);

    -- 2. Rental stores and unattended stations in six cities.
    INSERT INTO dbo.RentalStation (station_name, address, city, country, station_type)
    VALUES
    (N'Berlin Mitte Store', N'Friedrichstrasse 12', N'Berlin', N'Germany', N'Store'),
    (N'Berlin Alexanderplatz Station', N'Alexanderplatz 3', N'Berlin', N'Germany', N'Station'),
    (N'Hamburg Central Store', N'Bahnhofplatz 8', N'Hamburg', N'Germany', N'Store'),
    (N'Hamburg Hafen Station', N'Hafenstrasse 15', N'Hamburg', N'Germany', N'Station'),
    (N'Amsterdam Centrum Store', N'Canalstraat 21', N'Amsterdam', N'Netherlands', N'Store'),
    (N'Amsterdam Museumplein Station', N'Museumplein 6', N'Amsterdam', N'Netherlands', N'Station'),
    (N'Rotterdam Central Store', N'Stationsweg 9', N'Rotterdam', N'Netherlands', N'Store'),
    (N'Rotterdam Maas Station', N'Maasstraat 17', N'Rotterdam', N'Netherlands', N'Station'),
    (N'Helsinki Central Store', N'Asemakatu 4', N'Helsinki', N'Finland', N'Store'),
    (N'Helsinki Kamppi Station', N'Kampinkatu 10', N'Helsinki', N'Finland', N'Station'),
    (N'Tampere Centre Store', N'Keskuskatu 11', N'Tampere', N'Finland', N'Store'),
    (N'Tampere Tammela Station', N'Tammelankatu 7', N'Tampere', N'Finland', N'Station');

    -- 3. Customers. All phone numbers and addresses are test-only placeholders.
    INSERT INTO dbo.Customer
        (first_name, last_name, address, email, phone_number, city, country)
    VALUES
    (N'Mila', N'Fischer', N'Sample Road 1', N'berlin01@example.com', N'000-100-0001', N'Berlin', N'Germany'),
    (N'Emil', N'Weber', N'Sample Road 2', N'berlin02@example.com', N'000-100-0002', N'Berlin', N'Germany'),
    (N'Lara', N'Neumann', N'Sample Road 3', N'berlin03@example.com', N'000-100-0003', N'Berlin', N'Germany'),
    (N'Jonas', N'Becker', N'Sample Road 4', N'hamburg01@example.com', N'000-100-0004', N'Hamburg', N'Germany'),
    (N'Nina', N'Schulz', N'Sample Road 5', N'hamburg02@example.com', N'000-100-0005', N'Hamburg', N'Germany'),
    (N'Felix', N'Brandt', N'Sample Road 6', N'hamburg03@example.com', N'000-100-0006', N'Hamburg', N'Germany'),
    (N'Sophie', N'Bakker', N'Sample Road 7', N'amsterdam01@example.com', N'000-100-0007', N'Amsterdam', N'Netherlands'),
    (N'Daan', N'Visser', N'Sample Road 8', N'amsterdam02@example.com', N'000-100-0008', N'Amsterdam', N'Netherlands'),
    (N'Eva', N'Bos', N'Sample Road 9', N'amsterdam03@example.com', N'000-100-0009', N'Amsterdam', N'Netherlands'),
    (N'Lotte', N'van Dijk', N'Sample Road 10', N'rotterdam01@example.com', N'000-100-0010', N'Rotterdam', N'Netherlands'),
    (N'Sem', N'Mulder', N'Sample Road 11', N'rotterdam02@example.com', N'000-100-0011', N'Rotterdam', N'Netherlands'),
    (N'Tess', N'de Boer', N'Sample Road 12', N'rotterdam03@example.com', N'000-100-0012', N'Rotterdam', N'Netherlands'),
    (N'Ella', N'Korhonen', N'Sample Road 13', N'helsinki01@example.com', N'000-100-0013', N'Helsinki', N'Finland'),
    (N'Eero', N'Nieminen', N'Sample Road 14', N'helsinki02@example.com', N'000-100-0014', N'Helsinki', N'Finland'),
    (N'Iida', N'Salonen', N'Sample Road 15', N'helsinki03@example.com', N'000-100-0015', N'Helsinki', N'Finland'),
    (N'Olivia', N'Virtanen', N'Sample Road 16', N'tampere01@example.com', N'000-100-0016', N'Tampere', N'Finland'),
    (N'Mika', N'Lehtinen', N'Sample Road 17', N'tampere02@example.com', N'000-100-0017', N'Tampere', N'Finland'),
    (N'Saara', N'Koskinen', N'Sample Road 18', N'tampere03@example.com', N'000-100-0018', N'Tampere', N'Finland');

    -- 4. Store employees (not used for app-based station rentals).
    INSERT INTO dbo.Employee (first_name, last_name)
    VALUES
    (N'Lena', N'Meyer'),
    (N'Jan', N'Kruger'),
    (N'Noa', N'de Vries'),
    (N'Bram', N'Jansen'),
    (N'Aino', N'Laine'),
    (N'Olli', N'Virtanen');

    -- 5. Staging for rental headers.
    -- RentalRef is only a seed-script label; it is NOT a database column.
    DECLARE @RentalSeed TABLE (
        RentalRef CHAR(4) NOT NULL PRIMARY KEY,
        CustomerEmail NVARCHAR(60) NOT NULL,
        PickupName NVARCHAR(50) NOT NULL,
        ReturnName NVARCHAR(50) NOT NULL,
        EmployeeName NVARCHAR(110) NULL,
        StartDate DATETIME NOT NULL UNIQUE,
        EndDate DATETIME NOT NULL,
        PaymentMethod NVARCHAR(30) NOT NULL
    );

    INSERT INTO @RentalSeed
        (RentalRef, CustomerEmail, PickupName, ReturnName, EmployeeName,
         StartDate, EndDate, PaymentMethod)
    VALUES
    (N'R001', N'berlin01@example.com', N'Berlin Mitte Store', N'Berlin Alexanderplatz Station', N'Lena Meyer', N'2026-08-02T09:00:00', N'2026-08-02T10:10:00', N'Card'),
    (N'R002', N'berlin02@example.com', N'Berlin Alexanderplatz Station', N'Berlin Alexanderplatz Station', NULL, N'2026-08-04T12:20:00', N'2026-08-04T12:50:00', N'Card'),
    (N'R003', N'hamburg01@example.com', N'Hamburg Central Store', N'Hamburg Hafen Station', N'Jan Kruger', N'2026-08-06T10:00:00', N'2026-08-06T11:20:00', N'Card'),
    (N'R004', N'hamburg02@example.com', N'Hamburg Hafen Station', N'Hamburg Hafen Station', NULL, N'2026-08-08T16:10:00', N'2026-08-08T16:35:00', N'Card'),
    (N'R005', N'amsterdam01@example.com', N'Amsterdam Centrum Store', N'Amsterdam Museumplein Station', N'Noa de Vries', N'2026-08-10T09:30:00', N'2026-08-10T12:00:00', N'Invoice'),
    (N'R006', N'amsterdam02@example.com', N'Amsterdam Museumplein Station', N'Amsterdam Centrum Store', NULL, N'2026-08-12T14:05:00', N'2026-08-12T14:45:00', N'Card'),
    (N'R007', N'rotterdam01@example.com', N'Rotterdam Central Store', N'Rotterdam Maas Station', N'Bram Jansen', N'2026-08-14T10:10:00', N'2026-08-14T11:50:00', N'Card'),
    (N'R008', N'rotterdam02@example.com', N'Rotterdam Maas Station', N'Rotterdam Maas Station', NULL, N'2026-08-16T17:00:00', N'2026-08-16T17:25:00', N'Card'),
    (N'R009', N'helsinki01@example.com', N'Helsinki Central Store', N'Helsinki Kamppi Station', N'Aino Laine', N'2026-08-18T08:45:00', N'2026-08-18T10:15:00', N'Invoice'),
    (N'R010', N'helsinki02@example.com', N'Helsinki Kamppi Station', N'Helsinki Central Store', NULL, N'2026-08-20T18:20:00', N'2026-08-20T18:55:00', N'Card'),
    (N'R011', N'tampere01@example.com', N'Tampere Centre Store', N'Tampere Tammela Station', N'Olli Virtanen', N'2026-08-22T10:00:00', N'2026-08-22T12:20:00', N'Card'),
    (N'R012', N'tampere02@example.com', N'Tampere Tammela Station', N'Tampere Tammela Station', NULL, N'2026-08-24T13:50:00', N'2026-08-24T14:25:00', N'Card'),
    (N'R013', N'berlin03@example.com', N'Berlin Mitte Store', N'Berlin Mitte Store', N'Lena Meyer', N'2026-09-03T10:00:00', N'2026-09-03T13:20:00', N'Invoice'),
    (N'R014', N'berlin01@example.com', N'Berlin Alexanderplatz Station', N'Berlin Alexanderplatz Station', NULL, N'2026-09-05T16:10:00', N'2026-09-05T17:00:00', N'Card'),
    (N'R015', N'hamburg03@example.com', N'Hamburg Central Store', N'Hamburg Hafen Station', N'Jan Kruger', N'2026-09-07T11:15:00', N'2026-09-07T12:20:00', N'Card'),
    (N'R016', N'hamburg01@example.com', N'Hamburg Hafen Station', N'Hamburg Central Store', NULL, N'2026-09-09T14:30:00', N'2026-09-09T15:05:00', N'Card'),
    (N'R017', N'amsterdam03@example.com', N'Amsterdam Centrum Store', N'Amsterdam Museumplein Station', N'Noa de Vries', N'2026-09-11T08:30:00', N'2026-09-11T09:45:00', N'Card'),
    (N'R018', N'amsterdam01@example.com', N'Amsterdam Museumplein Station', N'Amsterdam Museumplein Station', NULL, N'2026-09-13T18:00:00', N'2026-09-13T18:35:00', N'Card'),
    (N'R019', N'rotterdam03@example.com', N'Rotterdam Central Store', N'Rotterdam Central Store', N'Bram Jansen', N'2026-09-15T09:05:00', N'2026-09-15T12:15:00', N'Invoice'),
    (N'R020', N'rotterdam01@example.com', N'Rotterdam Maas Station', N'Rotterdam Central Store', NULL, N'2026-09-17T14:15:00', N'2026-09-17T15:05:00', N'Card'),
    (N'R021', N'helsinki03@example.com', N'Helsinki Central Store', N'Helsinki Central Store', N'Aino Laine', N'2026-09-19T10:30:00', N'2026-09-19T12:30:00', N'Card'),
    (N'R022', N'helsinki01@example.com', N'Helsinki Kamppi Station', N'Helsinki Kamppi Station', NULL, N'2026-09-21T17:40:00', N'2026-09-21T18:20:00', N'Card'),
    (N'R023', N'tampere03@example.com', N'Tampere Centre Store', N'Tampere Tammela Station', N'Olli Virtanen', N'2026-09-23T08:50:00', N'2026-09-23T11:20:00', N'Invoice'),
    (N'R024', N'tampere01@example.com', N'Tampere Tammela Station', N'Tampere Centre Store', NULL, N'2026-09-25T15:10:00', N'2026-09-25T15:55:00', N'Card'),
    (N'R025', N'berlin01@example.com', N'Berlin Mitte Store', N'Berlin Alexanderplatz Station', N'Lena Meyer', N'2026-10-02T08:30:00', N'2026-10-02T10:15:00', N'Card'),
    (N'R026', N'berlin02@example.com', N'Berlin Alexanderplatz Station', N'Berlin Mitte Store', NULL, N'2026-10-04T16:10:00', N'2026-10-04T16:50:00', N'Card'),
    (N'R027', N'hamburg02@example.com', N'Hamburg Central Store', N'Hamburg Central Store', N'Jan Kruger', N'2026-10-06T10:00:00', N'2026-10-06T13:00:00', N'Invoice'),
    (N'R028', N'hamburg03@example.com', N'Hamburg Hafen Station', N'Hamburg Hafen Station', NULL, N'2026-10-08T13:30:00', N'2026-10-08T14:15:00', N'Card'),
    (N'R029', N'amsterdam02@example.com', N'Amsterdam Centrum Store', N'Amsterdam Museumplein Station', N'Noa de Vries', N'2026-10-10T11:20:00', N'2026-10-10T12:50:00', N'Card'),
    (N'R030', N'amsterdam03@example.com', N'Amsterdam Museumplein Station', N'Amsterdam Museumplein Station', NULL, N'2026-10-12T17:20:00', N'2026-10-12T18:05:00', N'Card'),
    (N'R031', N'rotterdam02@example.com', N'Rotterdam Central Store', N'Rotterdam Maas Station', N'Bram Jansen', N'2026-10-14T09:20:00', N'2026-10-14T11:20:00', N'Invoice'),
    (N'R032', N'rotterdam03@example.com', N'Rotterdam Maas Station', N'Rotterdam Central Store', NULL, N'2026-10-16T18:00:00', N'2026-10-16T18:35:00', N'Card'),
    (N'R033', N'helsinki02@example.com', N'Helsinki Central Store', N'Helsinki Kamppi Station', N'Aino Laine', N'2026-10-18T09:10:00', N'2026-10-18T10:35:00', N'Card'),
    (N'R034', N'helsinki03@example.com', N'Helsinki Kamppi Station', N'Helsinki Kamppi Station', NULL, N'2026-10-20T18:00:00', N'2026-10-20T18:30:00', N'Card'),
    (N'R035', N'tampere02@example.com', N'Tampere Centre Store', N'Tampere Centre Store', N'Olli Virtanen', N'2026-10-22T09:00:00', N'2026-10-22T13:40:00', N'Invoice'),
    (N'R036', N'tampere03@example.com', N'Tampere Tammela Station', N'Tampere Centre Store', NULL, N'2026-10-24T15:20:00', N'2026-10-24T16:05:00', N'Card');

    -- Make sure seeded rentals obey the channel, time and city assumptions.
    IF EXISTS (
        SELECT 1 FROM @RentalSeed AS s
        JOIN dbo.RentalStation AS p ON p.station_name = s.PickupName
        JOIN dbo.RentalStation AS rt ON rt.station_name = s.ReturnName
        WHERE s.EndDate <= s.StartDate
           OR p.city <> rt.city OR p.country <> rt.country
           OR (p.station_type = N'Store' AND s.EmployeeName IS NULL)
           OR (p.station_type = N'Station' AND s.EmployeeName IS NOT NULL)
           OR (s.PaymentMethod = N'Invoice' AND p.station_type <> N'Store')
    )
    BEGIN
        THROW 51001, 'Invalid channel, time, or return city in sample rentals.', 1;
    END;

    INSERT INTO dbo.RENTAL
        (customer_id, pickup_station_id, return_station_id, employee_id,
         start_date, end_date, payment_method)
    SELECT c.customer_id, pickup.rental_station_id, ret.rental_station_id,
           e.employee_id, s.StartDate, s.EndDate, s.PaymentMethod
    FROM @RentalSeed AS s
    JOIN dbo.Customer AS c ON c.email = s.CustomerEmail
    JOIN dbo.RentalStation AS pickup ON pickup.station_name = s.PickupName
    JOIN dbo.RentalStation AS ret ON ret.station_name = s.ReturnName
    LEFT JOIN dbo.Employee AS e
        ON CONCAT(e.first_name, N' ', e.last_name) = s.EmployeeName
    WHERE s.EmployeeName IS NULL OR e.employee_id IS NOT NULL;

    IF (SELECT COUNT(*) FROM dbo.RENTAL) <> (SELECT COUNT(*) FROM @RentalSeed)
    BEGIN
        THROW 51002, 'Rental insert count mismatch: inspect source lookups.', 1;
    END;

    -- 6. Rental line staging; line Price is a charge for that physical item.
    DECLARE @RentalLineSeed TABLE (
        RentalRef CHAR(4) NOT NULL,
        RentalLineNo INT NOT NULL,
        ModelName NVARCHAR(20) NOT NULL,
        BrandName NVARCHAR(50) NOT NULL,
        Price DECIMAL(10,2) NOT NULL,
        PRIMARY KEY (RentalRef, RentalLineNo)
    );

    INSERT INTO @RentalLineSeed (RentalRef, RentalLineNo, ModelName, BrandName, Price)
    VALUES
    (N'R001', 1, N'CityRide 3', N'UrbanMotion', 18),
    (N'R001', 2, N'Urban Glide', N'FlowWheel', 12),
    (N'R002', 1, N'Swift K2', N'ZipRide', 7),
    (N'R003', 1, N'Metro E2', N'VoltWay', 20),
    (N'R004', 1, N'Urban Glide', N'FlowWheel', 7),
    (N'R005', 1, N'CargoFlow 2', N'GreenHaul', 48),
    (N'R005', 2, N'CityRide 3', N'UrbanMotion', 33),
    (N'R006', 1, N'Swift K2', N'ZipRide', 9),
    (N'R007', 1, N'GoMoped 50', N'MoveTech', 34),
    (N'R008', 1, N'Urban Glide', N'FlowWheel', 8),
    (N'R009', 1, N'CityRide 3', N'UrbanMotion', 24),
    (N'R010', 1, N'Swift K2', N'ZipRide', 10),
    (N'R011', 1, N'Metro E2', N'VoltWay', 31),
    (N'R012', 1, N'Urban Glide', N'FlowWheel', 9),
    (N'R013', 1, N'CargoFlow 2', N'GreenHaul', 58),
    (N'R013', 2, N'Swift K2', N'ZipRide', 20),
    (N'R014', 1, N'Swift K2', N'ZipRide', 12),
    (N'R015', 1, N'SitGo X', N'Electra', 27),
    (N'R016', 1, N'Urban Glide', N'FlowWheel', 8),
    (N'R017', 1, N'CityRide 3', N'UrbanMotion', 22),
    (N'R018', 1, N'Swift K2', N'ZipRide', 9),
    (N'R019', 1, N'CargoFlow 2', N'GreenHaul', 62),
    (N'R019', 2, N'Metro E2', N'VoltWay', 45),
    (N'R020', 1, N'Urban Glide', N'FlowWheel', 12),
    (N'R021', 1, N'GoMoped 50', N'MoveTech', 37),
    (N'R022', 1, N'Swift K2', N'ZipRide', 11),
    (N'R023', 1, N'CityRide 3', N'UrbanMotion', 40),
    (N'R024', 1, N'Urban Glide', N'FlowWheel', 12),
    (N'R025', 1, N'Metro E2', N'VoltWay', 29),
    (N'R025', 2, N'Swift K2', N'ZipRide', 14),
    (N'R026', 1, N'Swift K2', N'ZipRide', 10),
    (N'R027', 1, N'CargoFlow 2', N'GreenHaul', 59),
    (N'R027', 2, N'CityRide 3', N'UrbanMotion', 41),
    (N'R028', 1, N'Urban Glide', N'FlowWheel', 10),
    (N'R029', 1, N'SitGo X', N'Electra', 32),
    (N'R029', 2, N'Swift K2', N'ZipRide', 15),
    (N'R030', 1, N'Swift K2', N'ZipRide', 12),
    (N'R031', 1, N'GoMoped 50', N'MoveTech', 38),
    (N'R032', 1, N'Urban Glide', N'FlowWheel', 10),
    (N'R033', 1, N'CityRide 3', N'UrbanMotion', 25),
    (N'R034', 1, N'Swift K2', N'ZipRide', 8),
    (N'R035', 1, N'CargoFlow 2', N'GreenHaul', 73),
    (N'R035', 2, N'Metro E2', N'VoltWay', 62),
    (N'R036', 1, N'Urban Glide', N'FlowWheel', 11);

    -- Each model has six physical units. RowNumber 1..6 assigns one to each
    -- city, so the same physical item is reused only within its city.
    DECLARE @CitySlot TABLE (
        City NVARCHAR(50) NOT NULL PRIMARY KEY,
        Country NVARCHAR(50) NOT NULL,
        SlotNo INT NOT NULL UNIQUE
    );
    INSERT INTO @CitySlot (City, Country, SlotNo)
    VALUES
    (N'Berlin', N'Germany', 1),
    (N'Hamburg', N'Germany', 2),
    (N'Amsterdam', N'Netherlands', 3),
    (N'Rotterdam', N'Netherlands', 4),
    (N'Helsinki', N'Finland', 5),
    (N'Tampere', N'Finland', 6);

    ;WITH EquipmentNumbered AS (
        SELECT ei.equipment_id, m.name AS ModelName, m.brand_name AS BrandName,
               ROW_NUMBER() OVER
                   (PARTITION BY ei.model_id ORDER BY ei.equipment_id) AS SlotNo
        FROM dbo.EquipmentItem AS ei
        JOIN dbo.Model AS m ON m.model_id = ei.model_id
    )
    INSERT INTO dbo.RentalLine (rental_id, rental_line_no, equipment_id, Price)
    SELECT r.rental_id, ln.RentalLineNo, eq.equipment_id, ln.Price
    FROM @RentalLineSeed AS ln
    JOIN @RentalSeed AS s ON s.RentalRef = ln.RentalRef
    JOIN dbo.RENTAL AS r ON r.start_date = s.StartDate
    JOIN dbo.RentalStation AS ps ON ps.rental_station_id = r.pickup_station_id
    JOIN @CitySlot AS cs ON cs.City = ps.city AND cs.Country = ps.country
    JOIN EquipmentNumbered AS eq
        ON eq.ModelName = ln.ModelName
       AND eq.BrandName = ln.BrandName
       AND eq.SlotNo = cs.SlotNo;

    IF (SELECT COUNT(*) FROM dbo.RentalLine) <> (SELECT COUNT(*) FROM @RentalLineSeed)
    BEGIN
        THROW 51003, 'Rental line insert count mismatch: check models / equipment slots.', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM dbo.RENTAL AS r
        LEFT JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id
        WHERE rl.rental_id IS NULL
    )
    BEGIN
        THROW 51004, 'A rental has no rental lines.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM dbo.RentalLine AS l1
        JOIN dbo.RENTAL AS r1 ON r1.rental_id = l1.rental_id
        JOIN dbo.RentalLine AS l2
          ON l2.equipment_id = l1.equipment_id AND l1.rental_id < l2.rental_id
        JOIN dbo.RENTAL AS r2 ON r2.rental_id = l2.rental_id
        WHERE r1.start_date < r2.end_date AND r2.start_date < r1.end_date
    )
    BEGIN
        THROW 51005, 'The same equipment item is double-booked.', 1;
    END;

    COMMIT TRANSACTION;
    PRINT 'Part 3 seed data inserted successfully (36 rentals, 44 rental lines).';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
