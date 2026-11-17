/*
*/
USE RentalDB;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Path comes from env.local.sql (your own copy, gitignored).
-- Run this script in SQLCMD Mode (Query menu -> SQLCMD Mode).
:r env.local.sql

DECLARE @CsvFile NVARCHAR(4000) = N'$(CsvFile)';

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.RENTAL)
       OR NOT EXISTS (SELECT 1 FROM dbo.RentalLine)
       OR NOT EXISTS (SELECT 1 FROM dbo.RentalStation WHERE station_name = N'Berlin Mitte Store')
    BEGIN
        THROW 52000, 'First run the original TestData-Part3.sql on a fresh RentalDB.', 1;
    END;


    IF (SELECT COUNT(*) FROM dbo.Model) <> 7
       OR EXISTS (
           SELECT 1
           FROM dbo.Model AS m
           LEFT JOIN dbo.EquipmentItem AS ei ON ei.model_id = m.model_id
           GROUP BY m.model_id
           HAVING COUNT(ei.equipment_id) NOT IN (6,7)
       )
    BEGIN
        THROW 52001, 'Unexpected model/equipment inventory: expected 7 models and 6 or 7 items per model.', 1;
    END;

    MERGE dbo.RentalStation WITH (HOLDLOCK) AS dest
    USING (VALUES
        (N'Stockholm City Store',       N'Samplegatan 10', N'Stockholm', N'Sweden', N'Store'),
        (N'Stockholm Central Station', N'Exempelgatan 5', N'Stockholm', N'Sweden', N'Station')
    ) AS src(station_name, address, city, country, station_type)
       ON dest.station_name = src.station_name
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (station_name, address, city, country, station_type)
        VALUES (src.station_name, src.address, src.city, src.country, src.station_type);

    MERGE dbo.Employee WITH (HOLDLOCK) AS dest
    USING (SELECT N'Astrid' AS first_name, N'Lund' AS last_name) AS src
       ON dest.first_name = src.first_name AND dest.last_name = src.last_name
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (first_name, last_name) VALUES (src.first_name, src.last_name);

    -- Add just the seventh physical item per model, if absent. The 7th slot
    -- belongs to Stockholm. This MERGE is safe to re-run for subsequent batches.
    ;WITH CurrentSlots AS (
        SELECT ei.model_id, ei.equipment_id,
               ROW_NUMBER() OVER (PARTITION BY ei.model_id ORDER BY ei.equipment_id) AS slot_no
        FROM dbo.EquipmentItem AS ei
    )
    MERGE dbo.EquipmentItem WITH (HOLDLOCK) AS dest
    USING (
        SELECT m.model_id, cs.equipment_id AS existing_seventh_item_id
        FROM dbo.Model AS m
        LEFT JOIN CurrentSlots AS cs
          ON cs.model_id = m.model_id AND cs.slot_no = 7
    ) AS src
       ON dest.equipment_id = src.existing_seventh_item_id
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (model_id, [Condition]) VALUES (src.model_id, N'Good');

    IF EXISTS (
        SELECT 1
        FROM dbo.Model AS m
        LEFT JOIN dbo.EquipmentItem AS ei ON ei.model_id = m.model_id
        GROUP BY m.model_id
        HAVING COUNT(ei.equipment_id) <> 7
    )
    BEGIN
        THROW 52002, 'Stockholm inventory could not be prepared correctly.', 1;
    END;

    -- Strings are used for the raw CSV dates and price so conversion errors
    -- can be detected explicitly rather than silently changing values.
    CREATE TABLE #CsvRaw (
        rental_ref NVARCHAR(20) NULL,
        customer_email NVARCHAR(60) NULL,
        customer_first_name NVARCHAR(50) NULL,
        customer_last_name NVARCHAR(50) NULL,
        customer_address NVARCHAR(100) NULL,
        customer_phone NVARCHAR(30) NULL,
        customer_city NVARCHAR(50) NULL,
        customer_country NVARCHAR(50) NULL,
        pickup_station NVARCHAR(100) NULL,
        return_station NVARCHAR(100) NULL,
        employee_name NVARCHAR(110) NULL,
        start_date_text NVARCHAR(30) NULL,
        end_date_text NVARCHAR(30) NULL,
        payment_method NVARCHAR(30) NULL,
        model_name NVARCHAR(50) NULL,
        brand_name NVARCHAR(50) NULL,
        price_text NVARCHAR(30) NULL
    );

    DECLARE @BulkSql NVARCHAR(MAX) =
          N'BULK INSERT #CsvRaw FROM '''
        + REPLACE(@CsvFile, N'''', N'''''')
        + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDTERMINATOR = '','', '
        + N'FIELDQUOTE = ''"'', ROWTERMINATOR = ''0x0a'', CODEPAGE = ''65001'', TABLOCK);';
    EXEC sys.sp_executesql @BulkSql;

    IF NOT EXISTS (SELECT 1 FROM #CsvRaw)
    BEGIN
        THROW 52003, 'CSV has no data rows.', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM #CsvRaw
        WHERE NULLIF(LTRIM(RTRIM(rental_ref)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(customer_email)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(customer_first_name)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(customer_last_name)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(model_name)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(brand_name)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(pickup_station)), N'') IS NULL
           OR NULLIF(LTRIM(RTRIM(return_station)), N'') IS NULL
           OR TRY_CONVERT(DATETIME, start_date_text, 126) IS NULL
           OR TRY_CONVERT(DATETIME, end_date_text, 126) IS NULL
           OR TRY_CONVERT(DECIMAL(10,2), price_text) IS NULL
           OR TRY_CONVERT(DECIMAL(10,2), price_text) <= 0
           OR payment_method IS NULL
           OR payment_method NOT IN (N'Card', N'Invoice')
    )
    BEGIN
        THROW 52004, 'CSV contains an invalid, blank, or unconvertible field.', 1;
    END;

    IF EXISTS (SELECT 1 FROM #CsvRaw GROUP BY rental_ref HAVING COUNT(*) > 1)
       OR EXISTS (SELECT 1 FROM #CsvRaw GROUP BY start_date_text HAVING COUNT(*) > 1)
    BEGIN
        THROW 52005, 'Duplicate rental_ref or start_date within this CSV.', 1;
    END;

    -- Each email can appear in multiple rentals, but its customer details
    -- must remain identical. DISTINCT then gives one MERGE source per email.
    IF EXISTS (
        SELECT customer_email
        FROM #CsvRaw
        GROUP BY customer_email
        HAVING COUNT(DISTINCT CONCAT(
            customer_first_name, N'|', customer_last_name, N'|',
            customer_address, N'|', customer_phone, N'|',
            customer_city, N'|', customer_country)) > 1
    )
    BEGIN
        THROW 52006, 'Inconsistent customer details for the same email.', 1;
    END;

    -- A matching email must represent the same person/city. Do not silently
    -- attach new rentals to a different existing customer with that email.
    IF EXISTS (
        SELECT 1 FROM #CsvRaw AS src
        JOIN dbo.Customer AS existing ON existing.email = src.customer_email
        WHERE existing.first_name <> src.customer_first_name
           OR existing.last_name <> src.customer_last_name
           OR existing.city <> src.customer_city
           OR existing.country <> src.customer_country
    )
    BEGIN
        THROW 52017, 'CSV customer email conflicts with an existing customer identity or city.', 1;
    END;

    ;WITH CustomerSource AS (
        SELECT DISTINCT customer_email, customer_first_name,
               customer_last_name, customer_address, customer_phone,
               customer_city, customer_country
        FROM #CsvRaw
    )
    MERGE dbo.Customer WITH (HOLDLOCK) AS dest
    USING CustomerSource AS src
       ON dest.email = src.customer_email
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (first_name, last_name, address, email, phone_number, city, country)
        VALUES (src.customer_first_name, src.customer_last_name, src.customer_address,
                src.customer_email, src.customer_phone, src.customer_city, src.customer_country);

    DECLARE @CitySlot TABLE (
        city NVARCHAR(50) NOT NULL PRIMARY KEY,
        country NVARCHAR(50) NOT NULL,
        slot_no INT NOT NULL UNIQUE
    );
    INSERT INTO @CitySlot (city, country, slot_no)
    VALUES (N'Berlin', N'Germany', 1),
           (N'Hamburg', N'Germany', 2),
           (N'Amsterdam', N'Netherlands', 3),
           (N'Rotterdam', N'Netherlands', 4),
           (N'Helsinki', N'Finland', 5),
           (N'Tampere', N'Finland', 6),
           (N'Stockholm', N'Sweden', 7);

    CREATE TABLE #Prepared (
        rental_ref NVARCHAR(20) NOT NULL PRIMARY KEY,
        customer_id INT NOT NULL,
        customer_city NVARCHAR(50) NOT NULL,
        customer_country NVARCHAR(50) NOT NULL,
        pickup_station_id INT NOT NULL,
        return_station_id INT NOT NULL,
        employee_id INT NULL,
        pickup_type NVARCHAR(30) NOT NULL,
        pickup_city NVARCHAR(50) NOT NULL,
        pickup_country NVARCHAR(50) NOT NULL,
        return_city NVARCHAR(50) NOT NULL,
        return_country NVARCHAR(50) NOT NULL,
        start_date DATETIME NOT NULL,
        end_date DATETIME NOT NULL,
        payment_method NVARCHAR(30) NOT NULL,
        equipment_id INT NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        VAT DECIMAL(19,2) NOT NULL
    );

    ;WITH EquipmentSlots AS (
        SELECT ei.equipment_id, m.name AS model_name, m.brand_name,
               ROW_NUMBER() OVER (PARTITION BY ei.model_id ORDER BY ei.equipment_id) AS slot_no
        FROM dbo.EquipmentItem AS ei
        JOIN dbo.Model AS m ON m.model_id = ei.model_id
    )
    INSERT INTO #Prepared (
        rental_ref, customer_id, customer_city, customer_country,
        pickup_station_id, return_station_id, employee_id, pickup_type,
        pickup_city, pickup_country, return_city, return_country,
        start_date, end_date, payment_method, equipment_id, price, VAT
    )
    SELECT raw.rental_ref, c.customer_id, c.city, c.country,
           p.rental_station_id, ret.rental_station_id, e.employee_id, p.station_type,
           p.city, p.country, ret.city, ret.country,
           TRY_CONVERT(DATETIME, raw.start_date_text, 126),
           TRY_CONVERT(DATETIME, raw.end_date_text, 126),
           raw.payment_method, eq.equipment_id,
           TRY_CONVERT(DECIMAL(10,2), raw.price_text),
           CAST(ROUND(CASE p.country
             WHEN N'Germany' THEN TRY_CONVERT(DECIMAL(10,2), raw.price_text) * 19.0 / 119.0
             WHEN N'Netherlands' THEN TRY_CONVERT(DECIMAL(10,2), raw.price_text) * 21.0 / 121.0
             WHEN N'Finland' THEN TRY_CONVERT(DECIMAL(10,2), raw.price_text) * 25.5 / 125.5
             WHEN N'Sweden' THEN TRY_CONVERT(DECIMAL(10,2), raw.price_text) * 25.0 / 125.0
             ELSE 0.0
           END, 2) AS DECIMAL(19,2)) AS VAT
    FROM #CsvRaw AS raw
    JOIN dbo.Customer AS c ON c.email = raw.customer_email
    JOIN dbo.RentalStation AS p ON p.station_name = raw.pickup_station
    JOIN dbo.RentalStation AS ret ON ret.station_name = raw.return_station
    JOIN @CitySlot AS cs ON cs.city = p.city AND cs.country = p.country
    JOIN EquipmentSlots AS eq ON eq.model_name = raw.model_name
                              AND eq.brand_name = raw.brand_name
                              AND eq.slot_no = cs.slot_no
    LEFT JOIN dbo.Employee AS e
           ON CONCAT(e.first_name, N' ', e.last_name) = NULLIF(raw.employee_name, N'');

    IF (SELECT COUNT(*) FROM #Prepared) <> (SELECT COUNT(*) FROM #CsvRaw)
    BEGIN
        THROW 52007, 'ID lookup failed or duplicated: check stations, model, city, employee, or customer.', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM #Prepared
        WHERE end_date <= start_date
           OR pickup_city <> return_city OR pickup_country <> return_country
           OR pickup_city <> customer_city OR pickup_country <> customer_country
           OR pickup_type NOT IN (N'Store', N'Station')
           OR (pickup_type = N'Station' AND employee_id IS NOT NULL)
           OR (pickup_type = N'Store' AND employee_id IS NULL)
           OR (payment_method = N'Invoice' AND pickup_type <> N'Store')
    )
    BEGIN
        THROW 52008, 'Invalid dates, city, employee, station type or payment channel.', 1;
    END;
    -- Crucial extra validation: a nonblank *unknown* employee must not be
    -- silently treated as NULL by the LEFT JOIN for unattended stations.
    IF EXISTS (
        SELECT 1 FROM #CsvRaw AS raw
        JOIN #Prepared AS p ON p.rental_ref = raw.rental_ref
        WHERE (NULLIF(raw.employee_name, N'') IS NOT NULL AND p.employee_id IS NULL)
           OR (NULLIF(raw.employee_name, N'') IS NULL AND p.employee_id IS NOT NULL)
    )
    BEGIN
        THROW 52009, 'Employee name did not resolve correctly.', 1;
    END;

    IF EXISTS (SELECT 1 FROM #Prepared GROUP BY start_date HAVING COUNT(*) > 1)
    BEGIN
        THROW 52010, 'Duplicate parsed start_date in CSV.', 1;
    END;

    -- Fail on an existing time collision unless the old rental is IDENTICAL.
    IF EXISTS (
        SELECT 1 FROM #Prepared AS s
        JOIN dbo.RENTAL AS r ON r.start_date = s.start_date
        WHERE r.customer_id <> s.customer_id
           OR r.pickup_station_id <> s.pickup_station_id
           OR r.return_station_id <> s.return_station_id
           OR ISNULL(r.employee_id, -1) <> ISNULL(s.employee_id, -1)
           OR r.end_date <> s.end_date
           OR r.payment_method <> s.payment_method
    )
    BEGIN
        THROW 52011, 'Existing RENTAL has the same start_date but different details: import stopped.', 1;
    END;

    -- Validate no physical item double booking inside this batch.
    IF EXISTS (
        SELECT 1 FROM #Prepared AS a
        JOIN #Prepared AS b
          ON a.rental_ref < b.rental_ref
         AND a.equipment_id = b.equipment_id
         AND a.start_date < b.end_date AND b.start_date < a.end_date
    )
    BEGIN
        THROW 52012, 'Two rows in the CSV overlap on the same physical equipment.', 1;
    END;

    -- Also detect equipment collisions with the original seed or prior batches.
    -- The equal start_date exception allows idempotent reruns of THIS rental.
    IF EXISTS (
        SELECT 1 FROM #Prepared AS s
        JOIN dbo.RentalLine AS l ON l.equipment_id = s.equipment_id
        JOIN dbo.RENTAL AS r ON r.rental_id = l.rental_id
        WHERE s.start_date < r.end_date AND r.start_date < s.end_date
          AND s.start_date <> r.start_date
    )
    BEGIN
        THROW 52013, 'Equipment conflicts with an existing rental; nothing imported.', 1;
    END;

    -- A customer cannot pick up two different rentals at overlapping times.
    IF EXISTS (
        SELECT 1 FROM #Prepared AS a
        JOIN #Prepared AS b
          ON a.rental_ref < b.rental_ref AND a.customer_id = b.customer_id
         AND a.start_date < b.end_date AND b.start_date < a.end_date
    )
       OR EXISTS (
        SELECT 1 FROM #Prepared AS s
        JOIN dbo.RENTAL AS r ON r.customer_id = s.customer_id
        WHERE s.start_date < r.end_date AND r.start_date < s.end_date
          AND s.start_date <> r.start_date
    )
    BEGIN
        THROW 52014, 'Customer has overlapping rental bookings.', 1;
    END;

    DECLARE @RentalActions TABLE (action_taken NVARCHAR(10));
    -- MERGE is INSERT-ONLY: matching start_date means the rental already exists.
    MERGE dbo.RENTAL WITH (HOLDLOCK) AS dest
    USING #Prepared AS src
       ON dest.start_date = src.start_date
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (customer_id, pickup_station_id, return_station_id, employee_id,
                start_date, end_date, payment_method)
        VALUES (src.customer_id, src.pickup_station_id, src.return_station_id,
                src.employee_id, src.start_date, src.end_date, src.payment_method)
    OUTPUT $action INTO @RentalActions;

    -- Compare existing rental lines BEFORE merging, and refuse silent edits.
    IF EXISTS (
        SELECT 1 FROM #Prepared AS s
        JOIN dbo.RENTAL AS r ON r.start_date = s.start_date
        JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id AND rl.rental_line_no = 1
        WHERE rl.equipment_id <> s.equipment_id
           OR rl.Price <> s.price OR rl.VAT <> s.VAT
    )
    BEGIN
        THROW 52015, 'Existing rental line has different equipment, price or VAT.', 1;
    END;

    DECLARE @LineActions TABLE (action_taken NVARCHAR(10));
    MERGE dbo.RentalLine WITH (HOLDLOCK) AS dest
    USING (
        SELECT r.rental_id, 1 AS rental_line_no, s.equipment_id, s.price, s.VAT
        FROM #Prepared AS s
        JOIN dbo.RENTAL AS r ON r.start_date = s.start_date
    ) AS src
       ON dest.rental_id = src.rental_id AND dest.rental_line_no = src.rental_line_no
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (rental_id, rental_line_no, equipment_id, Price, VAT)
        VALUES (src.rental_id, src.rental_line_no, src.equipment_id, src.price, src.VAT)
    OUTPUT $action INTO @LineActions;

    -- This batch must now be represented by one RENTAL and one RentalLine.
    IF (SELECT COUNT(*) FROM #Prepared AS s
        JOIN dbo.RENTAL AS r ON r.start_date = s.start_date) <> (SELECT COUNT(*) FROM #Prepared)
       OR (SELECT COUNT(*) FROM #Prepared AS s
           JOIN dbo.RENTAL AS r ON r.start_date = s.start_date
           JOIN dbo.RentalLine AS rl ON rl.rental_id = r.rental_id AND rl.rental_line_no = 1)
          <> (SELECT COUNT(*) FROM #Prepared)
    BEGIN
        THROW 52016, 'A staged rental or rental line is missing after the MERGE.', 1;
    END;

    COMMIT TRANSACTION;
    SELECT @CsvFile AS imported_csv,
           (SELECT COUNT(*) FROM #CsvRaw) AS staged_rentals,
           (SELECT COUNT(*) FROM @RentalActions) AS new_rentals_inserted,
           (SELECT COUNT(*) FROM @LineActions) AS new_rental_lines_inserted,
           (SELECT COUNT(*) FROM dbo.RENTAL) AS total_rentals_in_database,
           (SELECT COUNT(*) FROM dbo.RentalLine) AS total_rental_lines_in_database;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
