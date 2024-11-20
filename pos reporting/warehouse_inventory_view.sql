--shows the warehouse inventory for items
create or replace view pos_reporting.warehouse_inventory_view as 
(
with details as 
(
select
	wh.inventory_date
	,wh.walmart_item_number
	,w.supplier_stock_id
	,coalesce(w.product_name,wh.item_name) as product_name
	,wh.on_hand_warehouse_inventory_in_units_this_year as on_hand_qty
	,wh.on_order_warehouse_quantity_in_units_this_year as on_order_qty
	,wh.inserted_at
	,max(inventory_date) over (partition by walmart_item_number) as recent_inventory_date
from pos_reporting.whse_on_hands wh
left join wm_catalog w
on wh.walmart_item_number = w.item_num
where 1=1
--and ( wh.on_hand_warehouse_inventory_in_units_this_year !=0
--or wh.on_order_warehouse_quantity_in_units_this_year !=0
--)
--^ don't include any items that have zeros?
)
select
	inventory_date
	,walmart_item_number
	,supplier_stock_id
	,product_name
	,on_hand_qty
	,on_order_qty
	,inserted_at
from details
where inventory_date = recent_inventory_date

)