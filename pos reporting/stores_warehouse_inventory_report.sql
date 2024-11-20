--shows the stores warehouse and inventory numbers
create or replace view pos_reporting.stores_warehouse_inventory_report as 
(
select
	woh.walmart_item_number
	,ins.prime_item_nbr as prime_item_number
	,ins.vendor_nbr as vendor_number
	,woh.item_name
	,woh.on_hand_warehouse_inventory_in_units_this_year as warehouse_inventory
	,woh.on_order_warehouse_quantity_in_units_this_year as warehouse_on_order
	,ins.in_transit_qty as stores_in_transit
	,ins.in_warehouse_qty as stores_in_warehouse
	,ins.on_order_qty as stores_on_hand
	,ins.curr_repl_instock
from pos_reporting.whse_on_hands woh -- warehouse info
left join pos_reporting.inventory_stores ins -- stores info
on woh.walmart_item_number = ins.walmart_item_number
left join clean_data.master_com_list mcl
on woh.walmart_item_number = mcl.item_id
)
;
