
--fact table for the dsv 3p recon report on power bi
create or replace view power_bi.fact_dsv_recon_3p as 
(
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
from pos_reporting.dsv_orders_3p_recon dr
left join power_bi.dim_models dm
on dr.model = dm.model_name
left join power_bi.dim_wm_item_id di
on dr.item_id = di.item_id
left join power_bi.dim_product_names dp
on dr.product_name = dp.product_name
left join power_bi.wm_calendar_view cal
on dr.order_date = cal.date 
left join power_bi.dim_order_status os
on dr.status = os.order_status_name
left join cat_by_model cbm
on dr.model = cbm.model
left join account_manager_cat amc 
on cbm.cat = amc.category_name
left join power_bi.group_id_view g
on dr.item_id = g.tool_id
where dr.status !='Refund'
)
;