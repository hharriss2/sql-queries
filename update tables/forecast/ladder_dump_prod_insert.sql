--from the data_dump file from kev for the ladder report. this updates the raw data and 
create or replace view etl_views.ladder_dump_prod_insert as 
(

with ldr as --ladder dump raw
(-- raw ladder dump clean up 
select distinct
	replace(old_nbr,'d','')::bigint as item_number
	,"Prime_Item_Desc" as product_name
	,"CID" as item_id
	,LTRIM(RTRIM(wm_date,'_FCST'),'WK') as wm_date
	,units
--	,"Channel_type" as retail_type
from dapl_raw.wm_ladder_forecast
where 1=1
and "Channel_type" ='WMT.COM'
)
,cw as  --current week
(
select wm_year, wm_week
from power_bi.wm_calendar_view
where date = current_date
)
,ldr_2 as --ladder dump raw 2
(--2nd part in the ladder dump clean up
--joining the ladder to the current walmart date in order to find the correct year for the corresponding walmart week
select
ldr.item_number
,ldr.product_name
,ldr.item_id
,ldr.units
-- if the week is current week or higher, then it's current year. 
--ex. we are in week 202603. wks 1&2 will be for 2027, 3-52 will be for 2026
,case
	when ldr.wm_date::integer >=cw.wm_week::integer
	then cw.wm_year||ldr.wm_date
	else cw.wm_year::integer + 1 ||ldr.wm_date
	end as wm_date
,2 as retail_type_id
from ldr
join cw
on 1=1
)
select 
	item_number
	,product_name
	,item_id
	,units
	,ldr_2.wm_date
	,wtm.first_date as forecast_date
from ldr_2
left join lookups.wm_week_to_month wtm
on ldr_2.wm_date::integer = wtm.wm_date
)
;