--report for purchase orders for the di download
create view power_bi.fact_di_download as 
(
select
	po.po_ref_number as po_number
	,order_count_key as order_number
	,msl.item_id
	,po.customer_sk
	,order_date
	,shipped_date
	,cancel_by_date
	,po.model
	,msl.product_name
	,cbm.cat
	,cbm.sub_cat
	,order_line_number
	,order_line_quantity
	,dic.sell_price
	,order_line_price
	,order_line_status
	,dw.warehouse_number
	,dc.customer_nk as customer_number
	,dc.retailer_name
	,dc.retailer_type
	,dc.sales_type
from inventory.sf_purchase_orders po
left join dim_sources.sf_dim_customer dc
on po.customer_sk = dc.customer_sk
left join dim_sources.sf_dim_warehouse dw
on po.warehouse_sk = dw.warehouse_sk
left join cat_by_model cbm
on po.model = cbm.model
left join inventory.di_item_cost dic
on po.model = dic.model
left join clean_data.master_ships_list msl
on po.model = msl.model
where 1=1
and order_line_status in ('Order Created','Picker Created, Unknown Method')
and customer_name is not null
and customer_name in 
(
'Sam''s Club DI C'
,'Walmart Bulk DI A'
,'Wal-mart.com DI D'
,'Wal-Mart.com DI HOP'
,'Walmart DI A'
,'Walmart DI C'
,'Wal-Mart Stores DI D'
)
)
--limit 50000
;
