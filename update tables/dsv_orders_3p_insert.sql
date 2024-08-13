--view used to insert into the retail_link_pos table
--orders from seller center API will be inserted using this  viiew
create or replace view dapl_raw.dsv_orders_3p_insert_pos_view as 
(
with wc as -- walmart catalog for 3p data
(
select item_id
	,model
	,product_name
	,upc
	,inserted_at
from clean_data.wm_catalog_3p
)
,wcmax as --max inserted date for wc catalog
( -- models can repeat. we can't have that for the 3p pos data
select
	model
	,max(inserted_at) as date_compare
from wc
group by model
)
,wcf as --walmart catalog final
(
select wc.item_id
	,wc.model
	,wc.upc
	,wc.product_name
from wc
join wcmax
on wc.inserted_at = wcmax.date_compare
and wc.model = wcmax.model
)
,wcal as --wm calendar
(
select * 
from power_bi.wm_calendar_view
)
select dsv_order_id
	,coalesce(wcf.item_id,404) as item_id -- if no item id present, '404' will show up in the item id column 
	,wcf.upc
	,dsv.sku as model
	,wcf.product_name
	,order_date::date as sale_date
	,wcal.wm_date::integer -100 as wm_week
	,qty as units
	,order_total as sales
	,'3P' as item_type
    ,po_id
from pos_reporting.dsv_orders_3p dsv
left join wcf
on dsv.sku = wcf.model
left join wcal 
on wcal.date = dsv.order_date::date
where 1=1
and status != 'Cancelled'
)
;
