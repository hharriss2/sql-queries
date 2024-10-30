with s as  --ships
( -- finding the average monthly ships for drop ship and wm.com
select
	model
	,sum(units) as total_units
	,w.wm_date::integer as wm_date
	,min(wm_date::integer) as first_sale_week
from ships_schema.ships s 
join wm_calendar w
on s.date_shipped = w.date
where 1=1
--and date_shipped >=current_date - interval '14 months'
and retailer ='Walmart.com'
and sale_type = 'Drop Ship'
and wm_date !=(select wm_date from wm_calendar where date = current_date)
-- and s.model = '8620335WCOM' -- testing a model
group by model, w.wm_date

)
,cal_1 as --calendar step 1
( -- finding the month for calendar
--find the month/year and also just the month number
--calendar ends 12 months out
select distinct
	wcv.wm_date::integer as wm_date
	,wcv.wm_week::integer as wm_week
	,min(wcv.wmcal_id) over (partition by wm_date) as wm_cal_id
	,wm_year
	,wm_quarter
	,max(case when date = current_date then wm_date::integer else null end) over() as current_wm_date 
	--^finds the current wm_date/week
from power_bi.wm_calendar_view wcv
where date <=current_date + interval '27 weeks'
)
,cal as --calendar table
( --assigns a date to every model
select model as model_name
	,m.model_id
    ,cat
    ,sub_cat
	,wm_cal_id
	,cbm_id
	,wm_date
	,wm_week
	,current_wm_date
	,wm_year
	,wm_quarter
from cat_by_model cbm
join cal_1
on 1=1
join power_bi.dim_models m 
on cbm.model = m.model_name
-- where model = '8620335WCOM'
)
,s_agg_1 as --ships aggregate
( -- finding the total ships by model by month shipped
select
	model
	,wm_date
	,total_units
	,first_sale_week
from s
where 1=1 -- joining so every model gets the same amount of dates from CAL clause
order by wm_date
)
select 
	model_name
	,cal.wm_date
	,total_units
from cal
left join s_agg_1
on s_agg_1.model = cal.model_name
and s_agg_1.wm_date = cal.wm_date
and first_sale_week <=s_agg_1.wm_date
where 1=1