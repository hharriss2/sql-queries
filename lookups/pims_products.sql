-- current list of products 

create view lookups.pims_products as (
with p1 as 
	(
	select *
	from products_raw
	)
,p2 as
	(
	select model, max(inserted_at) as inserted_at
	from products_raw 
	group by model
	)
select p1.*
from p1
join p2
on p1.model = p2.model and p1.inserted_at = p2.inserted_at
)
;