
--fact table for the dsv 3p recon report on power bi
create or replace view power_bi.fact_dsv_recon_3p as 
(
with oz as  --origin zone
(-- find the origin state for items shipped
select distinct state
,statefullname as state_name
,zipcode
from zipcodes 
)
,dl as --disco list
( -- returns items that are in the discontinued list of products
select *
from lookups.internal_item_status_view
where item_status in 
('Production - Obsolete','Production - Site Closeout') -- these statuses are considered 'Disco'
)
select
	dr.dsv_order_id
	,dr.po_id
	,dr.tracking_number
	,cal.wmcal_id
	,dm.model_id
	,di.item_id_id
	,cbm.cbm_id
	,g.group_id_id
	,amc.account_manager_id
	,dp.product_name_id
	,os.order_status_id
	,dr.qty
	,dr.order_total
	,dr.commission_amt
	,dr.rate_amount
	,dr.state_abr
	,dr.state_name
    ,dr.is_suppression_model
	,oz.state as origin_state_abr
	,oz.state_name as origin_state_name
	,shipped_on::date - order_date::date as  ordered_to_ship_days
	,delivered_on::date - shipped_on::date as shipped_to_delivered_days
	,delivered_on::date -  order_date::date as ordered_to_delivered_days
	,case -- shows if model is on disco or not
		when dl.model is not null
		then 1
		else 0
		end as is_disco
from pos_reporting.dsv_orders_3p_recon dr
left join oz 
on oz.zipcode = dr.origin_postal_code
left join dim_sources.dim_models dm
on dr.model = dm.model_name
left join dim_sources.dim_wm_item_id di
on dr.item_id = di.item_id
left join dim_sources.dim_product_names dp
on dr.product_name = dp.product_name
left join power_bi.wm_calendar_view cal
on dr.order_date = cal.date 
left join dim_sources.dim_order_status os
on dr.status = os.order_status_name
left join cat_by_model cbm
on dr.model = cbm.model
left join account_manager_cat amc 
on cbm.cat = amc.category_name
left join power_bi.group_id_view g
on dr.item_id = g.tool_id
left join dl
on dr.model = dl.model
where dr.status !='Refund'
)
;