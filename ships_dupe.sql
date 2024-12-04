--finds if duplicate ships data has been added
create or replace view ships_schema.ships_dupes as (
with insert_key as 
(
	select inserted_date 
	from
	(
	select distinct inserted_at, inserted_at::date inserted_date
	from ships_schema.ships
	) t1
	group by inserted_date
	having count(inserted_date) >1

)
,dupe_model as 
(
	select model, date_shipped, units, retailer, inserted_at
	from ships_schema.ships
	where inserted_at::date in 
	(
	select inserted_date from insert_key
	)
)
select distinct 
 d1.model, d1.date_shipped, d1.units, d1.retailer, d1.inserted_at as inserted_at_1, d2.inserted_at as inserted_at_2
from dupe_model d1
join dupe_model d2
on d1.model = d2.model
and d1.date_shipped = d2.date_shipped
and (d1.inserted_at != d2.inserted_at and d1.inserted_at::date = d2.inserted_at::date)
and d1.units = d2.units
and d1.retailer = d2.retailer
where d1.date_shipped in ('2022-11-29','2022-11-28')
order by date_shipped desc
)
;