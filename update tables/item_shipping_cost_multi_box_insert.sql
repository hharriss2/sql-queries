--use this view to insert the multi box shipping costs into the item cost table
create view etl_views.item_shipping_cost_multi_box_insert as 
(

select model
	,zone_number
	,dest_zone
	,origin_zone
	,sum(weight) as weight
	,sum(length) as length
	,sum(width) as width
	,sum(height) as height
	,sum(shipping_cost) as shipping_cost
	,count(shipping_cost) as total_shipping_costs
from components.item_shipping_cost_tbl_multi_box
where shipping_cost is not null
group by model
	,zone_number
	,dest_zone
	,origin_zone
	)
;
