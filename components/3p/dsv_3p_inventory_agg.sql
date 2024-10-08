-- aggregate of how much inventory there is to sell for a model
--original is normally broken out by ship node
create or replace view components.dsv_3p_inventory_agg as 
( select
	model
	,sum(input_qty) as input_qty
	,sum(avail_to_sell_qty) as avail_to_sell_qty
	,sum(reserved_qty) as reserved_qty
from components.dsv_3p_inventory
group by model
)