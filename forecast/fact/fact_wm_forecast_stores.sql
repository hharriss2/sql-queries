--table used for the wm forecast sent to us by wm. comparing the store count and actual units and visualizing it in pbi

create or replace view power_bi.fact_wm_forecast_stores as 
(
with ssa as 
( -- bring in pos stores
select
	prime_item_nbr::bigint as item_number
	,wm_week::integer + 100 as wm_date
	,sum(pos_qty) as total_pos_units
from sales_stores_auto
where wm_week::integer >=202438
group by prime_item_nbr::bigint, wm_week::integer + 100
)
select distinct 
	fs.item_number
	,mcl.model
	,fs.product_name
	,fs.vendor_number
    ,fs.store_count
    ,fs.forecast_units
	,wcal.wm_date::integer as wm_date
    ,coalesce(ssa.total_pos_units,0) as total_pos
    ,coalesce(ssa.total_pos_units,0)::numeric(10,2)/ forecast_units::numeric(10,2) as consumption_perc
	,wcal.id
from forecast.wm_forecast_stores fs -- forecast uploaded from what walmart provides
left join clean_data.master_com_list mcl -- used to assign a model number
on fs.item_number = mcl.item_id
left join wm_calendar wcal
on fs.forecast_date = wcal.date
left join ssa
on ssa.item_number = fs.item_number
and wcal.wm_date::integer = ssa.wm_date
)
;
