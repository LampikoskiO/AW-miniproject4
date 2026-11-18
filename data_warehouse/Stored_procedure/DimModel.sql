
USE RentalDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_load_dimModel
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Merge model data into DimModel.
        MERGE INTO DimModel AS target
        USING (
            SELECT
                m.model_id,
                m.brand_name,
                m.name AS model_name,
                sc.name AS subcategory_name,
                c.name AS category_name
            FROM Model AS m
            INNER JOIN SubCategory AS sc
                ON m.sub_cat_id = sc.sub_cat_id
            INNER JOIN Category AS c
                ON c.category_id = sc.category_id
        ) AS source
        ON target.model_id = source.model_id

        WHEN MATCHED THEN
            UPDATE SET
                brand_name = source.brand_name,
                model_name = source.model_name,
                subcategory_name = source.subcategory_name,
                category_name = source.category_name

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                model_id,
                brand_name,
                model_name,
                subcategory_name,
                category_name
            )
            VALUES (
                source.model_id,
                source.brand_name,
                source.model_name,
                source.subcategory_name,
                source.category_name
            );

        -- Save number of affected rows.
        SET @RowsAffected = @@ROWCOUNT;

        -- Validate source against DimModel.
        IF EXISTS (
            SELECT
                m.model_id,
                m.brand_name,
                m.name AS model_name,
                sc.name AS subcategory_name,
                c.name AS category_name
            FROM Model AS m
            INNER JOIN SubCategory AS sc
                ON m.sub_cat_id = sc.sub_cat_id
            INNER JOIN Category AS c
                ON c.category_id = sc.category_id

            EXCEPT

            SELECT
                model_id,
                brand_name,
                model_name,
                subcategory_name,
                category_name
            FROM DimModel
        )
            THROW 50001,
                'DimModel validation failed; the transaction was rolled back.',
                1;

        COMMIT TRANSACTION;

        -- Log successful ETL execution.
        SET @EndTime = SYSDATETIME();

        INSERT INTO dbo.ETL_Log (
            procedure_name,
            start_time,
            end_time,
            rows_affected,
            status,
            error_message
        )
        VALUES (
            'usp_load_dimModel',
            @StartTime,
            @EndTime,
            @RowsAffected,
            'Success',
            NULL
        );

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @EndTime = SYSDATETIME();
        SET @ErrorMessage = ERROR_MESSAGE();

        -- Log failed ETL execution.
        INSERT INTO dbo.ETL_Log (
            procedure_name,
            start_time,
            end_time,
            rows_affected,
            status,
            error_message
        )
        VALUES (
            'usp_load_dimModel',
            @StartTime,
            @EndTime,
            0,
            'Failed',
            @ErrorMessage
        );

        THROW;
    END CATCH
END;
GO
