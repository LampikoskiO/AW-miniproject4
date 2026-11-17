-- Use the RentalDB database for the model dimension load and validation.
use RentalDB;
go

create or alter procedure dbo.usp_load_dimModel
as
begin
    set nocount on;
    set xact_abort on;

    begin try
        begin transaction;

        -- Merge model data into the DimModel table.
        -- The source data is assembled from the Model, SubCategory, and Category tables.
        merge into DimModel as target
        using (
            select model_id, brand_name, m.name as model_name, sc.name as subcategory_name, c.name as category_name
            from Model as m
            inner join SubCategory as sc
            on m.sub_cat_id = sc.sub_cat_id
            inner join Category as c
            on c.category_id = sc.category_id
        ) as source
        on target.model_id = source.model_id
        when matched then
            update set
                brand_name = source.brand_name,
                model_name = source.model_name,
                subcategory_name = source.subcategory_name,
                category_name = source.category_name
        when not matched by target then
            insert (model_id, brand_name, model_name, subcategory_name, category_name)
            values (source.model_id, source.brand_name, source.model_name, source.subcategory_name, source.category_name);

        -- Validate that the source data and the dimension contain the same rows.
        if exists (
            select model_id, brand_name, m.name as model_name, sc.name as subcategory_name, c.name as category_name
            from Model as m
            inner join SubCategory as sc
            on m.sub_cat_id = sc.sub_cat_id
            inner join Category as c
            on c.category_id = sc.category_id
            except
            select model_id, brand_name, model_name, subcategory_name, category_name
            from DimModel
            )
            throw 50001, 'DimModel validation failed; the transaction was rolled back.', 1;

        commit transaction;
    end try
    begin catch
        if xact_state() <> 0
            rollback transaction;
        throw;
    end catch
end;
go

exec dbo.usp_load_dimModel;