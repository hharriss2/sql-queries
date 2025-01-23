with si as  -- store inventory
( -- dataset is store inventory by store number. this clause aggregates it to the item level
select
	walmart_item_number
	,item_name
	,sum(store_in_transit_quantity_this_year) as store_in_transit_quantity_this_year
	,sum(store_in_warehouse_quantity_this_year) as store_in_warehouse_quantity_this_year
	,sum(store_on_hand_quantity_this_year) as store_on_hand_quantity_this_year
	,sum(store_on_order_quantity_this_year) as store_on_order_quantity_this_year
	,sum(store_in_transit_quantity_this_year) as store_in_transit_quantity_this_year
	,sum(traited_store_count_this_year) as traited_store_count_this_year
from inventory.wm_store_on_hands
where business_date = (select max(business_date) from inventory.wm_store_on_hands)
--^ use the inventory levels from today
)
select *
	,+store_in_warehouse_quantity_this_year
	+store_on_hand_quantity_this_year
	+store_on_order_quantity_this_year as stores_on_hand
from si