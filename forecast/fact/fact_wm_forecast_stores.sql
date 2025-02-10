--table used for the wm forecast sent to us by wm. comparing the store count and actual units and visualizing it in pbi

create or replace view power_bi.fact_wm_forecast_stores as 
(
with ssa as 
(
select
	prime_item_nbr::bigint as item_number
	,wm_week::integer + 100 as wm_date
	,sum(pos_qty) as total_pos_units
from sales_stores_auto
where wm_week::integer >=202438
and prime_item_nbr::bigint in 
(
select item_number
from forecast.wm_forecast_stores
)
group by prime_item_nbr::bigint, wm_week::integer + 100
)
,wf as --walmart forecast
(
select fs.*, wcal.wm_date
from forecast.wm_forecast_stores fs
join wm_calendar wcal 
on fs.forecast_date = wcal.date
)
,fs as --walmart forecast sequence
(-- finding the latest version and the previous units for that version
select * 
	,row_number() over (partition by vendor_number,item_number, forecast_date order by inserted_at desc)
	as forecast_version_seq
	,lag(forecast_units) over (partition by vendor_number,item_number, forecast_date order by inserted_at asc)
	 as previous_units
from wf
)
select distinct 
	fs.item_number
	,mcl.model
	,fs.product_name
	,fs.vendor_number
    ,fs.store_count
    ,fs.forecast_units
    ,fs.previous_units
	,wcal.wm_date::integer as wm_date
    ,coalesce(ssa.total_pos_units,0) as total_pos
    ,coalesce(ssa.total_pos_units,0)::numeric(10,2)/ forecast_units::numeric(10,2) as consumption_perc
	,wcal.id
	,cbm.cat
	,cbm.sub_cat
	,fs.forecast_date
from  fs -- forecast uploaded from what walmart provides
left join clean_data.master_com_list mcl -- used to assign a model number
on fs.item_number = mcl.item_id
left join wm_calendar wcal
on fs.forecast_date = wcal.date
left join ssa
on ssa.item_number = fs.item_number
and wcal.wm_date::integer = ssa.wm_date
left join cat_by_model cbm
on mcl.model = cbm.model
where 1=1
and fs.forecast_version_seq = 1
)
;
