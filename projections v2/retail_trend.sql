--testing out a new way to visualize retails for the 
create or replace view projections.retail_trend as 
(
with r as --retail pos
(
select item_id
	,sum(units) as total_units
	,avg((sales/nullif(units,0)))::numeric(10,2) as retail_price
    ,cal.wm_date::integer as wm_date
    ,min(cal.id) as wm_cal_id
from retail_link_pos rp
join wm_calendar cal 
on rp.sale_date = cal.date
where 1=1
and  units >0
and sales >0
 and item_id = 125464489
 group by item_id, cal.wm_date::integer
)
,rc as --r compare
( --showign the previous retail and previous unit columns for each row by week
select 
	item_id
	,wm_date
	,total_units
	,retail_price
    ,wm_cal_id
	,lag(retail_price) over (partition by item_id order by wm_date) as prev_retail
	,lag(total_units)  over (partition by item_id order by wm_date) as prev_units
from r
)
select 
	item_id
	,wm_date
    ,wm_cal_id
	,total_units
	,retail_price
	,prev_retail
	,prev_units
	,case -- will be used in power bi to indicate on a line chart when the retail spikes
		when abs(prev_retail - retail_price) >=5
		then retail_price
		else null
		end as is_retail_spike
	,((total_units - prev_units)/(nullif(prev_units,0))::numeric(10,2))::numeric(10,2) as perc_wow
from rc
)