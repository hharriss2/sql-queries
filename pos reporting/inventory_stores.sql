--store walmart item number and product information for the inventory levels.
--has on hands, on order, and in transity inventory quantities for stores

create or replace view pos_reporting.inventory_stores_view as 
(
with t1 as 
(
select *
from pos_reporting.inventory_stores iss
)
select t1.vendor_nbr as vendor_number
	,dv.vendor_name
	,t1.prime_item_nbr as prime_item_number
	,t1.walmart_item_number
	,coalesce(mcl.model,w.supplier_stock_id) as model
	,coalesce(w.product_name,mcl.product_name) as product_name
	,t1.curr_repl_instock
	,t1.on_hand_qty
	,t1.on_order_qty
	,t1.in_transit_qty
	,t1.inserted_at
from t1
left join wm_catalog w 
on t1.walmart_item_number = w.item_num
left join clean_data.master_com_list mcl
on w.item_num = mcl.item_id
left join dim_sources.dim_vendor dv
on t1.vendor_nbr::text = dv.vendor_id
where 1=1
)
;