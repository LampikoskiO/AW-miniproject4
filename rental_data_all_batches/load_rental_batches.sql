-- Run after initialize_rentaldb.sql.
-- Set @Batch once; equipment, maintenance, and rental files are selected together.
-- @Directory must be readable by the SQL Server service.
USE RentalDB;

GO
SET NOCOUNT ON;

SET XACT_ABORT ON;

DECLARE @Batch AS INT = 3;

DECLARE @Directory AS NVARCHAR (3500) = N'C:path\to\rental_data_all_batches\';

IF RIGHT(@Directory, 1) <> N'\'
    SET @Directory = @Directory + N'\';

IF @Batch NOT BETWEEN 1 AND 3
    THROW 53000, 'Invalid batch number', 1;

DECLARE @Suffix AS CHAR (2) = RIGHT('0' + CONVERT (VARCHAR (2), @Batch), 2);

DECLARE @EquipmentFile AS NVARCHAR (4000) = @Directory + N'equipment_items_batch_' + @Suffix + N'.csv';

DECLARE @MaintenanceFile AS NVARCHAR (4000) = @Directory + N'maintenance_batch_' + @Suffix + N'.csv';

DECLARE @CsvFile AS NVARCHAR (4000) = @Directory + N'rentals_batch_' + @Suffix + N'.csv';

DECLARE @BulkSql AS NVARCHAR (MAX);

-- Drop temp tables in case this script is rerun in the same session.
IF OBJECT_ID('tempdb..#EquipmentRaw') IS NOT NULL
    DROP TABLE #EquipmentRaw;
IF OBJECT_ID('tempdb..#MaintenanceRaw') IS NOT NULL
    DROP TABLE #MaintenanceRaw;
IF OBJECT_ID('tempdb..#CsvRaw') IS NOT NULL
    DROP TABLE #CsvRaw;
IF OBJECT_ID('tempdb..#Prepared') IS NOT NULL
    DROP TABLE #Prepared;

BEGIN TRY
    BEGIN TRANSACTION;
    CREATE TABLE #EquipmentRaw (
        equipment_id NVARCHAR (30),
        model_id     NVARCHAR (30),
        condition    NVARCHAR (30),
        aquired_date NVARCHAR (30),
        removed_date NVARCHAR (30),
        is_lost      NVARCHAR (30)
    );
    CREATE TABLE #MaintenanceRaw (
        equipment_id NVARCHAR (30),
        start_time   NVARCHAR (30),
        end_time     NVARCHAR (30),
        cost         NVARCHAR (30)
    );
    SET @BulkSql = N'BULK INSERT #EquipmentRaw FROM ''' + REPLACE(@EquipmentFile, '''', '''''') + N''' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDTERMINATOR='','',FIELDQUOTE=''"'',ROWTERMINATOR=''0x0a'',CODEPAGE=''65001'');';
    EXECUTE sys.sp_executesql @BulkSql;
    SET @BulkSql = N'BULK INSERT #MaintenanceRaw FROM ''' + REPLACE(@MaintenanceFile, '''', '''''') + N''' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDTERMINATOR='','',FIELDQUOTE=''"'',ROWTERMINATOR=''0x0a'',CODEPAGE=''65001'');';
    EXECUTE sys.sp_executesql @BulkSql;
    IF NOT EXISTS (SELECT 1
                   FROM   #EquipmentRaw)
       OR NOT EXISTS (SELECT 1
                      FROM   #MaintenanceRaw)
        THROW 53005, 'Equipment or maintenance CSV is empty', 1;
    IF EXISTS (SELECT 1
               FROM   #EquipmentRaw
               WHERE  TRY_CONVERT (INT, equipment_id) IS NULL
                      OR TRY_CONVERT (INT, model_id) IS NULL
                      OR TRY_CONVERT (DATE, aquired_date, 23) IS NULL
                      OR TRY_CONVERT (DATE, removed_date, 23) IS NULL
                      OR TRY_CONVERT (BIT, is_lost) IS NULL)
        THROW 53001, 'Invalid equipment CSV', 1;
    IF EXISTS (SELECT 1
               FROM   #MaintenanceRaw
               WHERE  TRY_CONVERT (INT, equipment_id) IS NULL
                      OR TRY_CONVERT (DATETIME, start_time, 126) IS NULL
                      OR TRY_CONVERT (DATETIME, end_time, 126) IS NULL
                      OR TRY_CONVERT (DECIMAL (10, 2), cost) IS NULL)
        THROW 53002, 'Invalid maintenance CSV', 1;
    CREATE TABLE #CsvRaw (
        rental_ref          NVARCHAR (20) ,
        customer_email      NVARCHAR (60) ,
        customer_first_name NVARCHAR (50) ,
        customer_last_name  NVARCHAR (50) ,
        customer_address    NVARCHAR (100),
        customer_phone      NVARCHAR (30) ,
        customer_city       NVARCHAR (50) ,
        customer_country    NVARCHAR (50) ,
        pickup_station      NVARCHAR (100),
        return_station      NVARCHAR (100),
        employee_name       NVARCHAR (110),
        start_date_text     NVARCHAR (30) ,
        end_date_text       NVARCHAR (30) ,
        payment_method      NVARCHAR (30) ,
        model_name          NVARCHAR (50) ,
        brand_name          NVARCHAR (50) ,
        price_text          NVARCHAR (30) ,
        equipment_id_text   NVARCHAR (30) ,
        rental_line_no_text NVARCHAR (30) 
    );
    SET @BulkSql = N'BULK INSERT #CsvRaw FROM ''' + REPLACE(@CsvFile, '''', '''''') + N''' WITH (FORMAT=''CSV'',FIRSTROW=2,FIELDTERMINATOR='','',FIELDQUOTE=''"'',ROWTERMINATOR=''0x0a'',CODEPAGE=''65001'',TABLOCK);';
    EXECUTE sys.sp_executesql @BulkSql;
    IF NOT EXISTS (SELECT 1
                   FROM   #CsvRaw)
        THROW 52000, 'CSV empty', 1;
    IF EXISTS (SELECT 1
               FROM   #CsvRaw
               WHERE  TRY_CONVERT (DATETIME, start_date_text, 126) IS NULL
                      OR TRY_CONVERT (DATETIME, end_date_text, 126) <= TRY_CONVERT (DATETIME, start_date_text, 126)
                      OR TRY_CONVERT (INT, equipment_id_text) IS NULL
                      OR TRY_CONVERT (INT, rental_line_no_text) IS NULL
                      OR TRY_CONVERT (DECIMAL (10, 2), price_text) <= 0
                      OR payment_method NOT IN ('Card', 'Invoice'))
        THROW 52001, 'Invalid CSV values', 1;
    IF EXISTS (SELECT   1
               FROM     #CsvRaw
               GROUP BY rental_ref, rental_line_no_text
               HAVING   COUNT(*) > 1)
        THROW 52002, 'Duplicate rental line', 1;
    IF EXISTS (SELECT   1
               FROM     #CsvRaw
               GROUP BY rental_ref
               HAVING   COUNT(DISTINCT start_date_text) > 1
                        OR COUNT(DISTINCT customer_email) > 1
                        OR COUNT(DISTINCT pickup_station) > 1
                        OR COUNT(DISTINCT return_station) > 1
                        OR COUNT(DISTINCT end_date_text) > 1
                        OR COUNT(DISTINCT payment_method) > 1
                        OR COUNT(DISTINCT ISNULL(employee_name, '')) > 1)
        THROW 52003, 'Inconsistent rental header', 1;
    IF EXISTS (SELECT 1
               FROM   #CsvRaw AS x
                      INNER JOIN
                      dbo.Customer AS c
                      ON c.email = x.customer_email
               WHERE  c.first_name <> x.customer_first_name
                      OR c.last_name <> x.customer_last_name
                      OR c.city <> x.customer_city
                      OR c.country <> x.customer_country)
        THROW 52004, 'Customer identity mismatch', 1;
    IF EXISTS (SELECT 1
               FROM   #EquipmentRaw AS x
                      INNER JOIN
                      dbo.EquipmentItem AS e
                      ON e.equipment_id = TRY_CONVERT (INT, x.equipment_id))
        THROW 53003, 'Equipment already imported', 1;
    SET IDENTITY_INSERT dbo.EquipmentItem ON;
    INSERT dbo.EquipmentItem (
        equipment_id,
        model_id,
        [Condition],
        aquired_date,
        removed_date,
        is_lost
    )
    SELECT CONVERT (INT, equipment_id),
           CONVERT (INT, model_id),
           condition,
           CONVERT (DATE, aquired_date, 23),
           CONVERT (DATE, removed_date, 23),
           CONVERT (BIT, is_lost)
    FROM   #EquipmentRaw;
    SET IDENTITY_INSERT dbo.EquipmentItem OFF;
    IF EXISTS (SELECT 1
               FROM   #MaintenanceRaw AS x
               WHERE  NOT EXISTS (SELECT 1
                                  FROM   dbo.EquipmentItem AS e
                                  WHERE  e.equipment_id = TRY_CONVERT (INT, x.equipment_id)))
        THROW 53004, 'Maintenance refers to missing equipment', 1;
    INSERT dbo.Maintenance (
        equipment_id,
        start_time,
        end_time,
        cost
    )
    SELECT CONVERT (INT, equipment_id),
           CONVERT (DATETIME, start_time, 126),
           CONVERT (DATETIME, end_time, 126),
           CONVERT (DECIMAL (10, 2), cost)
    FROM   #MaintenanceRaw;
    WITH src
    AS   (SELECT DISTINCT customer_email,
                          customer_first_name,
                          customer_last_name,
                          customer_address,
                          customer_phone,
                          customer_city,
                          customer_country
          FROM   #CsvRaw)
    INSERT dbo.Customer (
        first_name,
        last_name,
        address,
        email,
        phone_number,
        city,
        country
    )
    SELECT s.customer_first_name,
           s.customer_last_name,
           s.customer_address,
           s.customer_email,
           s.customer_phone,
           s.customer_city,
           s.customer_country
    FROM   src AS s
    WHERE  NOT EXISTS (SELECT 1
                       FROM   dbo.Customer AS c
                       WHERE  c.email = s.customer_email);
    CREATE TABLE #Prepared (
        rental_ref     NVARCHAR (20)  ,
        customer_id    INT            ,
        pickup_id      INT            ,
        return_id      INT            ,
        employee_id    INT             NULL,
        start_date     DATETIME       ,
        end_date       DATETIME       ,
        payment_method NVARCHAR (30)  ,
        equipment_id   INT            ,
        line_no        INT            ,
        price          DECIMAL (10, 2),
        VAT            DECIMAL (19, 2)
    );
    INSERT #Prepared
    SELECT x.rental_ref,
           c.customer_id,
           p.rental_station_id,
           t.rental_station_id,
           e.employee_id,
           CONVERT (DATETIME, x.start_date_text, 126),
           CONVERT (DATETIME, x.end_date_text, 126),
           x.payment_method,
           CONVERT (INT, x.equipment_id_text),
           CONVERT (INT, x.rental_line_no_text),
           CONVERT (DECIMAL (10, 2), x.price_text),
           CAST (ROUND(CONVERT (DECIMAL (10, 2), x.price_text) * CASE p.country WHEN 'Germany' THEN 19.0 / 119 WHEN 'Netherlands' THEN 21.0 / 121 WHEN 'Finland' THEN 25.5 / 125.5 WHEN 'Sweden' THEN 25.0 / 125 ELSE 0 END, 2) AS DECIMAL (19, 2))
    FROM   #CsvRaw AS x
           INNER JOIN
           dbo.Customer AS c
           ON c.email = x.customer_email
           INNER JOIN
           dbo.RentalStation AS p
           ON p.station_name = x.pickup_station
           INNER JOIN
           dbo.RentalStation AS t
           ON t.station_name = x.return_station
           INNER JOIN
           dbo.EquipmentItem AS eq
           ON eq.equipment_id = TRY_CONVERT (INT, x.equipment_id_text)
           INNER JOIN
           dbo.Model AS m
           ON m.model_id = eq.model_id
              AND m.name = x.model_name
              AND m.brand_name = x.brand_name
           LEFT OUTER JOIN
           dbo.Employee AS e
           ON CONCAT(e.first_name, ' ', e.last_name) = NULLIF (x.employee_name, '');
    IF (SELECT COUNT(*)
        FROM   #Prepared) <> (SELECT COUNT(*)
                              FROM   #CsvRaw)
        THROW 52005, 'Failed to resolve customer, station, model or equipment', 1;
    IF EXISTS (SELECT 1
               FROM   #Prepared AS x
                      INNER JOIN
                      dbo.RentalStation AS p
                      ON p.rental_station_id = x.pickup_id
                      INNER JOIN
                      dbo.RentalStation AS t
                      ON t.rental_station_id = x.return_id
                      INNER JOIN
                      dbo.Customer AS c
                      ON c.customer_id = x.customer_id
                      INNER JOIN
                      dbo.EquipmentItem AS eq
                      ON eq.equipment_id = x.equipment_id
               WHERE  p.city <> t.city
                      OR p.country <> t.country
                      OR p.city <> c.city
                      OR p.country <> c.country
                      OR (p.station_type = 'Station'
                          AND x.employee_id IS NOT NULL)
                      OR (p.station_type = 'Store'
                          AND x.employee_id IS NULL)
                      OR (x.payment_method = 'Invoice'
                          AND p.station_type <> 'Store')
                      OR CAST (x.start_date AS DATE) < eq.aquired_date
                      OR CAST (x.end_date AS DATE) > eq.removed_date)
        THROW 52006, 'Station, employee, city or equipment date constraint violated', 1;
    IF EXISTS (SELECT   1
               FROM     #Prepared
               GROUP BY start_date
               HAVING   COUNT(DISTINCT rental_ref) > 1)
       OR EXISTS (SELECT 1
                  FROM   #Prepared AS p
                         INNER JOIN
                         dbo.RENTAL AS r
                         ON r.start_date = p.start_date)
        THROW 52007, 'Duplicate start date (batch or database)', 1;
    IF EXISTS (SELECT 1
               FROM   #Prepared AS a
                      INNER JOIN
                      #Prepared AS b
                      ON a.equipment_id = b.equipment_id
                         AND (a.start_date < b.end_date
                              AND b.start_date < a.end_date)
                         AND (a.rental_ref <> b.rental_ref
                              OR a.line_no <> b.line_no))
       OR EXISTS (SELECT 1
                  FROM   #Prepared AS p
                         INNER JOIN
                         dbo.RentalLine AS l
                         ON l.equipment_id = p.equipment_id
                         INNER JOIN
                         dbo.RENTAL AS r
                         ON r.rental_id = l.rental_id
                  WHERE  p.start_date < r.end_date
                         AND r.start_date < p.end_date)
        THROW 52008, 'Equipment rental overlap', 1;
    IF EXISTS (SELECT 1
               FROM   (SELECT DISTINCT rental_ref,
                                       customer_id,
                                       start_date,
                                       end_date
                       FROM   #Prepared) AS a
                      INNER JOIN
                      (SELECT DISTINCT rental_ref,
                                       customer_id,
                                       start_date,
                                       end_date
                       FROM   #Prepared) AS b
                      ON a.rental_ref < b.rental_ref
                         AND a.customer_id = b.customer_id
                         AND a.start_date < b.end_date
                         AND b.start_date < a.end_date)
       OR EXISTS (SELECT 1
                  FROM   #Prepared AS p
                         INNER JOIN
                         dbo.RENTAL AS r
                         ON r.customer_id = p.customer_id
                  WHERE  p.start_date < r.end_date
                         AND r.start_date < p.end_date)
        THROW 52009, 'Customer rental overlap', 1;
    IF EXISTS (SELECT 1
               FROM   #Prepared AS p
                      INNER JOIN
                      dbo.Maintenance AS m
                      ON m.equipment_id = p.equipment_id
               WHERE  p.start_date < m.end_time
                      AND m.start_time < p.end_date)
        THROW 52010, 'Rental overlaps maintenance', 1;
    WITH headers
    AS   (SELECT DISTINCT rental_ref,
                          customer_id,
                          pickup_id,
                          return_id,
                          employee_id,
                          start_date,
                          end_date,
                          payment_method
          FROM   #Prepared)
    INSERT dbo.RENTAL (
        customer_id,
        pickup_station_id,
        return_station_id,
        employee_id,
        start_date,
        end_date,
        payment_method
    )
    SELECT customer_id,
           pickup_id,
           return_id,
           employee_id,
           start_date,
           end_date,
           payment_method
    FROM   headers;
    INSERT dbo.RentalLine (
        rental_id,
        rental_line_no,
        equipment_id,
        Price,
        VAT
    )
    SELECT r.rental_id,
           p.line_no,
           p.equipment_id,
           p.price,
           p.VAT
    FROM   #Prepared AS p
           INNER JOIN
           dbo.RENTAL AS r
           ON r.start_date = p.start_date;
    COMMIT TRANSACTION;
    SELECT @Batch AS batch_number,
           @EquipmentFile AS equipment_file,
           @MaintenanceFile AS maintenance_file,
           @CsvFile AS rental_file,
           (SELECT COUNT(*)
            FROM   #EquipmentRaw) AS equipment_items,
           (SELECT COUNT(*)
            FROM   #MaintenanceRaw) AS maintenance_records,
           COUNT(DISTINCT rental_ref) AS rentals,
           COUNT(*) AS rental_lines
    FROM   #Prepared;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    BEGIN TRY
        SET IDENTITY_INSERT dbo.EquipmentItem OFF;
    END TRY
    BEGIN CATCH
    END CATCH;
    THROW;
END CATCH