
create or replace view power_bi.fact_inventory_warehouse as 
(
with sa as --store aggregate
( -- summing up inventory quantities by item by store
 select all_links_item_number
	,walmart_item_number
	,store_number
	,distribution_center_number as rdc
	,storage_distribution_center_number as idc
	,store_in_transit_quantity_this_year
	,store_in_warehouse_quantity_this_year
	,store_on_hand_quantity_this_year
	,store_on_order_quantity_this_year
	,store_in_transit_quantity_this_year
	+store_in_warehouse_quantity_this_year
	+store_on_hand_quantity_this_year
	+store_on_order_quantity_this_year as stores_on_hand
from dapl_raw.store_on_hands
where business_date = (select max(business_date) from dapl_raw.store_on_hands)
)
,wh as 
(
select * 
from inventory.wm_warehouse_on_hands
)
select 
	sa.all_links_item_number
	,sa.walmart_item_number
	,din.item_number_id
	,sa.store_number
	,ws.store_id
	,rdc
	,sdc.rdc_id
	,idc
	,dc.idc_id
	,store_in_transit_quantity_this_year
	,store_on_hand_quantity_this_year
	,store_on_order_quantity_this_year
	,store_in_warehouse_quantity_this_year
	,on_hand_warehouse_inventory_in_units_this_year
	,on_order_warehouse_quantity_in_units_this_year
	,stores_on_hand
	,case -- used to create inventory push store report.
		when store_on_hand_quantity_this_year =0
		and store_on_order_quantity_this_year =1
		and on_hand_warehouse_inventory_in_units_this_year > 10
		and store_in_warehouse_quantity_this_year =0
		and store_in_transit_quantity_this_year =0
		then 1 else 0
		end as is_push_action
	,case -- current logic for finding domestic inventory
		when stores_on_hand = 0
		then 1
		else 0 end as is_domestic
	,sum(stores_on_hand) over (partition by sa.walmart_item_number, idc) 
	+ on_hand_warehouse_inventory_in_units_this_year 
	as final_on_hand_by_idc -- sum up stores inventory and add it to the warehouse number
		--on PBI, this should be able to group by Item #, IDC, final OH & be unique rows.
from sa
left join wh 
on sa.walmart_item_number = wh.walmart_item_number
and sa.rdc = distribution_center_number
and sa.idc = storage_distribution_center_number
left join power_bi.dim_item_number din
on sa.walmart_item_number = din.item_number
left join power_bi.dim_storage_distribution_center sdc
on sa.idc = sdc.storage_distribution_center_number
left join power_bi.dim_distribution_center dc
on sa.rdc = dc.distribution_center_number
left join power_bi.dim_wm_store ws
on sa.store_number = ws.store_number
)
;
