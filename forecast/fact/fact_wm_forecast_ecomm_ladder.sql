--this source takes the ladder data and mimics the fact_wm_forecast_stores.sql file. 
-- appended on hte power bi side an dused for the wm forecast report. 
create or replace view power_bi.fact_wm_forecast_ecomm_ladder as 
(
with rs as --retail sales
(
select item_id
	,wm_week + 100 as wm_date
	,sum(units) as total_pos_units
from retail_link_pos
where 1=1
and item_id in
	(
	select item_id
	from forecast.ladder_dump	
	)
group by item_id
	,wm_week + 100
)
,wf as 
(
select *
from forecast.ladder_dump
)
,fs as --walmart forecast sequence
( -- finding the latest version and previous units for that version
select *
	,row_number() over (partition by item_id, wm_date order by inserted_at desc)
	as forecast_version_seq
	,lag(units) over (partition by item_id, wm_date order by inserted_at asc)
	as previous_units
from wf
)
select
	fs.item_id
	,mcl.model
	,fs.product_name
	,fs.units as forecast_units
	,fs.previous_units
	,fs.wm_date::integer as wm_date
	,coalesce(rs.total_pos_units,0) as total_pos
	,coalesce(rs.total_pos_units,0)::numeric(10,2)/ nullif(fs.units::numeric(10,2),0) as consumption_perc
	,wcal.id
	,cbm.cat
	,cbm.sub_cat
	,fs.forecast_date
    ,2 as retail_type_id
from fs
left join clean_data.master_com_list mcl
on fs.item_id = mcl.item_id
left join wm_calendar wcal
on fs.forecast_date = wcal.date
left join rs
on rs.item_id = fs.item_id
and wcal.wm_date::integer = rs.wm_date
left join cat_by_model cbm
on mcl.model = cbm.model
where 1=1
and fs.forecast_version_seq = 1
)
;