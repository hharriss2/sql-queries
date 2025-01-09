create or replace view power_bi.fact_stores_monthly_forecast as 
(
with dcf as --distribution center forecast
( -- grouping up the forecast by idc and rdc
select
walmart_item_number
,soh.item_name
,soh.distribution_center_number
,soh.storage_distribution_center_number
,sum(wsf.forecast_quantity)/ 4 as forecast_quantity_by_week -- divide by 4 to find weekly average for forecast
--,wm.month_seq
--,wm.week_average
from inventory.wm_store_on_hands soh
join forecast.wm_store_forecast wsf
on soh.walmart_item_number = wsf.prime_item_number
and soh.store_number = wsf.store_number
--join lookups.wm_month_ordering_next_year wm
--on 1=1
--where 1=1
--and soh.walmart_item_number = 7138794
group by 
walmart_item_number
,soh.item_name
,soh.distribution_center_number
,soh.storage_distribution_center_number
)
-- find forecast quantity with the month & week average
select 
	walmart_item_number
	,item_name
	,distribution_center_number
	,storage_distribution_center_number
	,forecast_quantity_by_week
	,wm.month_seq
	,wm.month_name
	,wm.week_average -- avg number of weeks in the month
from dcf
join lookups.wm_month_ordering_next_year wm -- attatching to get each month tied to each record
on 1=1
)
;
