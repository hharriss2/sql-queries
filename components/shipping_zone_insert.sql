--query gives each item a zone 2-8
insert into components.item_shipping_cost_tbl
(
	model
	,length
	,width
	,height
	,weight
	,origin_zone
	,dest_zone
	,zone_number
)
select
	model
	,length
	,width
	,height
	,weight
	,origin_zone
	,dest_zone
	,zone_number
from lookups.dsv_item_cost_3p i 
join lookups.zone_zips z
on 1=1
where model not in 
(
select model
from components.item_shipping_cost_tbl
)
;
