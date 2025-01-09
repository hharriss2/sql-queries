--a report with just the warehouse numbers 
create or replace view power_bi.fact_warehouse_on_hands as 
(
with sfc as --stores forecast
( -- find the forecast by walmart item number, idc & rdc so we can join it up to the warehouse numbers
select
walmart_item_number
,soh.distribution_center_number
,soh.storage_distribution_center_number
,sum(wsf.forecast_quantity) dc_forecast_quantity
from inventory.wm_store_on_hands soh
left join forecast.wm_store_forecast wsf
on soh.walmart_item_number = wsf.prime_item_number
and soh.store_number = wsf.store_number
group by walmart_item_number,distribution_center_number,storage_distribution_center_number
)
select woh.*
	,cbm.cbm_id
	,din.item_number_id
	,sfc.dc_forecast_quantity/4 as dc_forecast_quantity
from inventory.wm_warehouse_on_hands woh
left join sfc
on woh.walmart_item_number = sfc.walmart_item_number
and woh.distribution_center_number = sfc.distribution_center_number
left join clean_data.master_com_list mcl
on woh.walmart_item_number = mcl.item_id
left join cat_by_model cbm 
on mcl.model = cbm.model
left join dim_sources.dim_item_number din
on woh.walmart_item_number = din.item_number
)
;
