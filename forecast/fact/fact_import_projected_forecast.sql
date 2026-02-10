--used in the wm forecast power bi report
--shows the store item total units for the forecasted week

create or replace view power_bi.fact_import_projected_forecast as 
(
select
	prime_item_nbr as item_id
	,coalesce(mcl.product_name, ipf.item_desc_1) as product_name
	,mcl.model
	,cbm.cat
	,order_projection_wm_date
	,projection_date
	,order_projection_units
	,min(order_projection_wm_date) over (partition by ipf.inserted_at) first_projection_wm_date
	,wcv.wm_date::integer as projected_ship_wm_date
from  forecast.import_projected_forecast ipf
left join clean_data.master_com_list mcl
on ipf.prime_item_nbr = mcl.item_id
left join cat_by_model cbm
on mcl.model = cbm.model
left join power_bi.wm_calendar_view wcv
on wcv.date::date = projection_date::date
)
;
