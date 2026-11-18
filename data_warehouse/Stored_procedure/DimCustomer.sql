USE RentalDB;
GO
--Creating the stored procedure
CREATE OR ALTER PROCEDURE dbo.LoadDimCustomer
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Started DATETIME2 = SYSDATETIME();
    DECLARE @Loaded INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert only customers that do not already exist
        INSERT INTO dbo.DimCustomer
        (
            customer_id,
            first_name,
            last_name,
            address,
            email,
            phone_number,
            city,
            country
        )
        SELECT
            cr.customer_id,
            cr.first_name,
            cr.last_name,
            cr.address,
            cr.email,
            cr.phone_number,
            cr.city,
            COALESCE(cr.country, 'Unknown')
        FROM RentalDB.dbo.Customer AS cr
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DimCustomer AS c
            WHERE c.customer_id = cr.customer_id
        );

        -- Count inserted rows
        SET @Loaded = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Log successful execution
        INSERT INTO dbo.EtlLog
        (
            target_table,
            started_at,
            ended_at,
            rows_loaded,
            status
        )
        VALUES
        (
            'DimCustomer',
            @Started,
            SYSDATETIME(),
            @Loaded,
            'Success'
        );

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Log failed execution
        INSERT INTO dbo.EtlLog
        (
            target_table,
            started_at,
            ended_at,
            status,
            error_number,
            error_message
        )
        VALUES
        (
            'DimCustomer',
            @Started,
            SYSDATETIME(),
            'Failed',
            ERROR_NUMBER(),
            ERROR_MESSAGE()
        );

        THROW;
    END CATCH
END;
GO
