ALTER TABLE dbo.FactMaintenance
ALTER COLUMN end_date_key INT NULL;
-- the dimdate updated version needs to be run as well if you get an error with the procedure

CREATE OR ALTER PROCEDURE dbo.usp_LoadFactMaintenance
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @started datetime2 = SYSDATETIME(), @loaded int;

    BEGIN TRY
        BEGIN TRANSACTION; -- all-or-nothing: if anything fails, nothing is written

        INSERT INTO FactMaintenance
            (model_key, equipment_key, start_date_key, end_date_key,
             maintenance_id, maintenance_cost, maintenance_time_min, maintenance_time_day)
        SELECT
            dm.model_key, -- DIM (DimModel): warehouse surrogate key, looked up via the item's model
            deq.equipment_key, -- DIM (DimEquipment): warehouse surrogate key

            CONVERT(int, CONVERT(char(8), m.start_time, 112)) AS start_date_key,

            -- If maintenance is not finished, there is no actual end date yet
            CASE
                WHEN m.end_time IS NULL
                     OR CONVERT(date, m.end_time) = '99991231'
                THEN NULL
                ELSE CONVERT(int, CONVERT(char(8), m.end_time, 112))
            END AS end_date_key,

            m.maintenance_id, -- OPERATIONAL: business id from source
            m.cost, -- OPERATIONAL: maintenance cost

            -- If maintenance is not finished, duration = 0 minutes
            CASE
                WHEN m.end_time IS NULL
                     OR CONVERT(date, m.end_time) = '99991231'
                THEN 0
                ELSE DATEDIFF_BIG(MINUTE, m.start_time, m.end_time)
            END AS maintenance_time_min,

            -- If maintenance is not finished, duration = 0 days
            CASE
                WHEN m.end_time IS NULL
                     OR CONVERT(date, m.end_time) = '99991231'
                THEN 0
                ELSE DATEDIFF(DAY, m.start_time, m.end_time)
            END AS maintenance_time_day

        FROM Maintenance AS m
        JOIN EquipmentItem AS ei
            ON ei.equipment_id = m.equipment_id
        JOIN DimModel AS dm
            ON dm.model_id = ei.model_id
        JOIN DimEquipment AS deq
            ON deq.equipment_id = m.equipment_id

        WHERE NOT EXISTS (
            SELECT 1
            FROM FactMaintenance AS f
            WHERE f.maintenance_id = m.maintenance_id
        );

        SET @loaded = @@ROWCOUNT;

        -- VALIDATION 1:
        -- Every maintenance event must exist in FactMaintenance
        IF EXISTS (
            SELECT 1
            FROM Maintenance AS m
            WHERE NOT EXISTS (
                SELECT 1
                FROM FactMaintenance AS f
                WHERE f.maintenance_id = m.maintenance_id
            )
        )
            THROW 53001,
                'A maintenance event is missing from the fact (a dimension key failed to resolve).', 1;

        -- VALIDATION 2:
        -- Fact table must have the same number of rows as the source
        IF (SELECT COUNT(*) FROM FactMaintenance)
           <> (SELECT COUNT(*) FROM Maintenance)
            THROW 53002,
                'Fact row count does not match the source Maintenance count.', 1;

        -- If both validations pass, commit the transaction
        COMMIT TRANSACTION;

        -- LOGGING SUCCESS
        INSERT INTO EtlLog
            (target_table, started_at, ended_at, rows_loaded, status)
        VALUES
            ('FactMaintenance', @started, SYSDATETIME(), @loaded, 'Success');

    END TRY

    BEGIN CATCH

        -- Roll back if something failed
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- LOGGING FAILURE
        INSERT INTO EtlLog
            (target_table, started_at, ended_at, status, error_number, error_message)
        VALUES
            ('FactMaintenance', @started, SYSDATETIME(),
             'Failed', ERROR_NUMBER(), ERROR_MESSAGE());

        THROW;

    END CATCH;
END;
GO



/*CREATE OR ALTER PROCEDURE dbo.usp_LoadFactMaintenance
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON

    DECLARE @started datetime2 = SYSDATETIME(), @loaded int

    BEGIN TRY
        BEGIN TRANSACTION   -- all-or-nothing: if anything fails, nothing is written

        -- Load (idempotent): insert only maintenance events not already in the fact.
        INSERT INTO FactMaintenance
            (model_key, equipment_key, start_date_key, end_date_key,
            maintenance_id, maintenance_cost, maintenance_time_min, maintenance_time_day)
        SELECT
            dm.model_key,                                                        -- DIM (DimModel): warehouse surrogate key, looked up via the item's model
            deq.equipment_key,                                                   -- DIM (DimEquipment): warehouse surrogate key
            CONVERT(int, CONVERT(char(8), m.start_time, 112)) AS start_date_key, -- OPERATIONAL (Maintenance.start_time) -> YYYYMMDD int key
            CONVERT(int, CONVERT(char(8), m.end_time,   112)) AS end_date_key,   -- OPERATIONAL (Maintenance.end_time)   -> YYYYMMDD int key
            m.maintenance_id,                                                    -- OPERATIONAL (Maintenance.maintenance_id): business id from source
            m.cost,                                                              -- OPERATIONAL (Maintenance.cost): measure from source
            DATEDIFF(MINUTE, m.start_time, m.end_time) AS maintenance_time_min,  -- OPERATIONAL (Maintenance.start_time/end_time): duration in minutes
            DATEDIFF(DAY,    m.start_time, m.end_time) AS maintenance_time_day   -- OPERATIONAL (Maintenance.start_time/end_time): duration in days
        FROM Maintenance AS m                                                    -- OPERATIONAL source table (grain: one row per maintenance event)
        JOIN EquipmentItem AS ei      ON ei.equipment_id = m.equipment_id        -- OPERATIONAL source table: the physical item -> its model
        JOIN DimModel AS dm           ON dm.model_id = ei.model_id               -- DIM: look up model_key by model id
        JOIN DimEquipment AS deq      ON deq.equipment_id = m.equipment_id       -- DIM: look up equipment_key by equipment id
        WHERE NOT EXISTS (                                                       -- skip events already loaded (rerunnable)
            SELECT 1 FROM FactMaintenance f
            WHERE f.maintenance_id = m.maintenance_id         -- we compare the maintenance_id to see if this event is already in the fact table
        );

        SET @loaded = @@ROWCOUNT   -- how many new fact rows were inserted (capture right after the INSERT)


-- VALIDATION 1: we are making sure that every maintenance event must have landed in the fact table atleast once (it has a matchin pair)

        IF EXISTS (
            SELECT 1 FROM Maintenance AS m
            WHERE NOT EXISTS ( -- check if the maintenance event is in the fact table
                SELECT 1 FROM FactMaintenance AS f
                WHERE f.maintenance_id = m.maintenance_id -- TRUE = it exists in both tables so we happy
            )
        )
            THROW 53001, 'A maintenance event is missing from the fact (a dimension key failed to resolve).', 1

-- VALIDATION 2: we are making sure that the fact table has the same number of rows as the source maintenance table

        IF (SELECT COUNT(*) FROM FactMaintenance) <> (SELECT COUNT(*) FROM Maintenance)
            THROW 53002, 'Fact row count does not match the source Maintenance count.', 1

-- IF WE PASS BOTH VALIDATIONS, WE COMMIT THE TRANSACTION AND LOG THE SUCCESS

		COMMIT TRANSACTION -- Successful, yippee!! we happy :)

 -- LOGGING STUFF FOR THE LOG TABLE

        INSERT INTO EtlLog (target_table, started_at, ended_at, rows_loaded, status) -- LOGGING STUFF FOR THE LOG TABLE
        VALUES ('FactMaintenance', @started, SYSDATETIME(), @loaded, 'Success'); -- (this table, when it started, when it ended, how many rows were loaded, and whether it succeeded or failed)
    END TRY

    BEGIN CATCH -- if try block fails we begin the catch block
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION -- if the transaction is still open, roll it back

		INSERT INTO EtlLog (target_table, started_at, ended_at, status, error_number, error_message) -- LOGGING STUFF FOR THE LOG TABLE
        VALUES ('FactMaintenance', @started, SYSDATETIME(), 'Failed', ERROR_NUMBER(), ERROR_MESSAGE()); -- (this table, when it started, when it ended, whether it succeeded or failed, the error number and the error message)
        THROW -- THROW the error message, angrily.. failure is not acceptable! >:(
    END CATCH

END
GO*/
