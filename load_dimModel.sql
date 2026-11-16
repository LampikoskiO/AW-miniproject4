-- Use the RentalDB database for the model dimension load and validation.
use RentalDB;
go

-- Insert model data into the DimModel table.
-- The source data is assembled from the Model, SubCategory, and Category tables.
insert into DimModel
select model_id, brand_name, m.name as model_name, sc.name as subcategory_name, c.name as category_name
from Model as m 
inner join SubCategory as sc
on m.sub_cat_id = sc.sub_cat_id
inner join Category as c
on c.category_id = sc.category_id;

go

-- Validate the load by checking whether the source data and the dimension are identical.
-- This query should return 0 rows if the load was successful and no differences remain.
select model_id, brand_name, m.name as model_name, sc.name as subcategory_name, c.name as category_name
from Model as m 
inner join SubCategory as sc
on m.sub_cat_id = sc.sub_cat_id
inner join Category as c
on c.category_id = sc.category_id 

INTERSECT

select model_id, brand_name, model_name, subcategory_name, category_name
from DimModel;
go

