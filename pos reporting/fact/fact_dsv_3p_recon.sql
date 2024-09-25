--fact table for the dsv 3p recon report on power bi
create or replace view power_bi.fact_dsv_recon_3p as 
(
select
	dr.dsv_order_id
	,dr.po_id
	,dr.tracking_number
	,dr.order_date
	,dm.model_id
	,di.item_id_id
	,dr.model
	,dp.product_name_id
	,dr.product_name
	,cal.wmcal_id
	,os.order_status_id
	,dr.qty
	,dr.order_total
	,dr.commission_amt
	,dr.rate_amount
	,dr.state_abr
	,dr.state_name
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
)
;
