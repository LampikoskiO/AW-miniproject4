CREATE OR ALTER PROCEDURE dbo.usp_LoadFactRentalLine
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @started datetime2 = SYSDATETIME(), @loaded int

    BEGIN TRY
        BEGIN TRANSACTION   -- all-or-nothing: if anything fails, nothing is written

        -- Load (idempotent): insert only rental lines not already in the fact.
        INSERT INTO FactRentalLine
            (rental_id, rental_line_no, customer_key, employee_key, model_key,
            start_date_key, end_date_key, pickup_station_key, return_station_key,
            price, VAT, datetime_start, datetime_end, payment_method, rental_time_minutes)
        SELECT
            r.rental_id,
            rl.rental_line_no,
            dc.customer_key,                                                     -- surrogate key from DimCustomer
            de.Employee_key,                                                     -- NULL for station rentals (LEFT JOIN)
            dm.model_key,                                                        -- surrogate key from DimModel
            CONVERT(int, CONVERT(char(8), r.start_date, 112)) AS start_date_key, -- date -> YYYYMMDD int key
            CONVERT(int, CONVERT(char(8), r.end_date,   112)) AS end_date_key,   -- same for the end date
            drs1.rental_station_key AS pickup_station_key,                       -- pickup station surrogate key
            drs2.rental_station_key AS return_station_key,                       -- return station surrogate key
            rl.Price,                                                            -- measure: line price from source
            rl.VAT,                                                              -- measure: line VAT from source
            r.start_date AS datetime_start,                                      -- keep the full timestamp in the fact
            r.end_date   AS datetime_end,
            r.payment_method,
            DATEDIFF(MINUTE, r.start_date, r.end_date) AS rental_time_minutes    -- duration in minutes
        FROM RentalLine AS rl                                                    -- grain: one row per rental line
        JOIN RENTAL AS r              ON r.rental_id = rl.rental_id              -- the rental header for each line
        JOIN DimCustomer AS dc        ON dc.customer_id = r.customer_id          -- look up customer_key by business id
        LEFT JOIN DimEmployee AS de   ON de.employee_id = r.employee_id          -- LEFT so station rentals (no employee) stay
        JOIN EquipmentItem AS ei      ON ei.equipment_id = rl.equipment_id       -- the physical item -> its model
        JOIN DimModel AS dm           ON dm.model_id = ei.model_id               -- look up model_key by model id
        JOIN DimRentalStation AS drs1 ON drs1.rental_station_id = r.pickup_station_id   -- pickup station key
        JOIN DimRentalStation AS drs2 ON drs2.rental_station_id = r.return_station_id   -- return station key
        WHERE NOT EXISTS (                                                       -- skip lines already loaded (rerunnable)
            SELECT 1 FROM FactRentalLine f
            WHERE f.rental_id = r.rental_id
            AND f.rental_line_no = rl.rental_line_no
        );

        SET @loaded = @@ROWCOUNT   -- how many new fact rows were inserted (capture right after the INSERT)


-- VALIDATION 1: we are making sure that every rental line must have landed in the fact table atleast once (it has a matchin pair)

        IF EXISTS (
            SELECT 1 FROM RentalLine AS rl
            WHERE NOT EXISTS ( -- check if the rental line is in the fact table
                SELECT 1 FROM FactRentalLine AS f
                WHERE f.rental_id = rl.rental_id AND f.rental_line_no = rl.rental_line_no -- TRUE = it exists in both tables so we happy
            )
        )
            THROW 53001, 'A rental line is missing from the fact (a dimension key failed to resolve).', 1

-- VALIDATION 2: we are making sure that the fact table has the same number of rows as the source rental line table

        IF (SELECT COUNT(*) FROM FactRentalLine) <> (SELECT COUNT(*) FROM RentalLine)
            THROW 53002, 'Fact row count does not match the source RentalLine count.', 1		
		
-- IF WE PASS BOTH VALIDATIONS, WE COMMIT THE TRANSACTION AND LOG THE SUCCESS

		COMMIT TRANSACTION -- Successful, yippee!! we happy :)

 -- LOGGING STUFF FOR THE LOG TABLE

        INSERT INTO EtlLog (target_table, started_at, ended_at, rows_loaded, status) -- LOGGING STUFF FOR THE LOG TABLE
        VALUES ('FactRentalLine', @started, SYSDATETIME(), @loaded, 'Success'); -- (this table, when it started, when it ended, how many rows were loaded, and whether it succeeded or failed)
    END TRY

    BEGIN CATCH -- if try block fails we begin the catch block
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION -- if the transaction is still open, roll it back
        
		INSERT INTO EtlLog (target_table, started_at, ended_at, status, error_number, error_message) -- LOGGING STUFF FOR THE LOG TABLE
        VALUES ('FactRentalLine', @started, SYSDATETIME(), 'Failed', ERROR_NUMBER(), ERROR_MESSAGE()); -- (this table, when it started, when it ended, whether it succeeded or failed, the error number and the error message)
        THROW -- THROW the error message, angrily.. failure is not acceptable! >:(
    END CATCH

END
GO
