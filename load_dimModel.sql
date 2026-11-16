use RentalDB;
go

-- insert

insert into DimModel
select model_id, brand_name, m.name as model_name, sc.name as subcategory_name, c.name as category_name
from Model as m 
inner join SubCategory as sc
on m.sub_cat_id = sc.sub_cat_id
inner join Category as c
on c.category_id = sc.category_id;

go

-- validate

-- should return 0 rows

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

