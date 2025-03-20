--uses the data from  https://docs.google.com/spreadsheets/d/17BJlAfeTeaYT7rKJo1xMCOl4OJaNYwCBtO5JUKF_97Q/edit?gid=0#gid=0
--finds the pos units for store and dotcom itesm and compares them to the forecast commit
--forecast commit provided by PD
create or replace view power_bi.fact_wm_forecast_commit_tracker as 
(

with ww as --walmart week
( -- table for a walmart week assigned to every date 
--will left join to everything else 
select
distinct
	wm_week::integer as wm_week
	,wm_year::integer as wm_year
	,wm_date::integer as wm_date
from power_bi.wm_calendar_view
where wm_date >='202301'
and wm_date <='202701'
)
,fc as --forecast commit
( -- gives the starting commit day for the forecast
select * 
from pos_reporting.wm_forecast_commit
)
,wwfc as --walmart week fc
(
select
	ww.wm_date
	,ww.wm_week
	,ww.wm_year
	,fc.wm_week as commit_start_week
	,fc.wm_year as commit_start_year
	,fc.item_id
	,fc.product_name
	,fc.units_per_week_forecast
	,fc.annual_unit_forecast
	,fc.commit_tag
	,fc.store_count
	,fc.commit_comments
	,fc.is_special_buy
from ww
left join fc
on 1=1
where 1=1
--and  item_id = '7033013565'
and ww.wm_date >=fc.wm_date
)
,eu as  -- ecommerce units
( --finds the units by item for each wm week & year
select item_id
	,wm_week as wm_date
	,left(wm_week::text,4)::integer as wm_year
	,right(wm_week::text,2)::integer as wm_week
	,sum(units) as total_ecomm_units
from retail_link_pos
where item_id in (select item_id from pos_reporting.wm_forecast_commit where commit_tag = 'dotcom')
and left(wm_week::text,4)::integer >=2023
group by item_id, wm_week
)
,su as  -- store units
( --finds the units by item for each wm week & year
select prime_item_nbr::bigint
	,wm_week as wm_date
	,left(wm_week::text,4)::integer as wm_year
	,right(wm_week::text,2)::integer as wm_week
	,sum(pos_qty) as total_store_units
from sales_stores_auto
where prime_item_nbr in (select item_id::text from pos_reporting.wm_forecast_commit where commit_tag = 'store')
and left(wm_week::text,4)::integer >=2023
group by prime_item_nbr::bigint, wm_week
)
select wwfc.*
	,coalesce(eu.total_ecomm_units,su.total_store_units,0) as total_pos_units
from wwfc
left join eu
on wwfc.item_id = eu.item_id
and wwfc.wm_date::integer = eu.wm_date
left join su
on wwfc.item_id = su.prime_item_nbr
and wwfc.wm_date::integer = su.wm_date
where 1=1



)
;
