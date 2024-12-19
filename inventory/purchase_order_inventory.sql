--putting purchase orders and inventory together. 
--This is an example of joining the inventory per item per warehouse with the PO per item per warehouse
-- shows the inventory for the item while subtracting the purchase order
with po as --purchase orders
(
select
	model
	,product_name
	,warehouse_name
	,warehouse_number
	,customer_name
	,sale_type
	,coalesce(shipped_date, cancel_by_date - interval '7 days') as shipped_date
	,cancel_by_date
	,order_count_key
	,order_line_quantity
from inventory.sf_purchase_orders
where model = '14727BLK22W'
)
,ii as --item inventory
( -- inventory by item by warehouse
select * 
	,quantity_on_hand + open_order_quantity + on_water_quantity + po_quantity as total_oh
from inventory.sf_item_inventory
where model = '14727BLK22W'
)
,poii as --purchase orders item inventory
( -- joining purchase orders and item inventory together to find out the amount of purchase orders that can be fulfilled
select 
	po.model
	,po.product_name
	,po.warehouse_name
	,po.warehouse_number
	,po.shipped_date
	,po.cancel_by_date
	,total_oh
	,order_line_quantity
	,order_count_key
	,sum(order_line_quantity) over (partition by po.model, po.warehouse_number order by po.shipped_date, order_count_key)
	as po_qty_warehouse_order_count -- summing up the order line quantity in order by the 'order count key' column
from po
left join ii
on po.model = ii.model
and po.warehouse_number::integer = ii.warehouse_number
where 1=1
order by po.warehouse_number, shipped_date
)
select 
	model
	,product_name
	,warehouse_name
	,warehouse_number
	,shipped_date
	,cancel_by_date
	,total_oh - po_qty_warehouse_order_count as remaining_inventory
	,order_line_quantity::integer as po_qty
from poii
order by warehouse_number, shipped_date
;
