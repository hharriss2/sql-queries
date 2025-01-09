--used to be part of the projected_units_by_week view
--find shte average ships for each model and projects them out by 26 weeks
create or replace view projections.last_ships_by_week as 
(
with s as  --ships
( -- find the total units sold by model by wm week
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
	,current_wm_week_seq
	,max(case when date = current_date then wm_date::integer else null end) over() as current_wm_date 
	--^finds the current wm_date/week
from power_bi.wm_calendar_view wcv
where date <=current_date + interval '52 weeks'
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
	,current_wm_week_seq
from cat_by_model cbm
join cal_1
on 1=1
join dim_sources.dim_models m 
on cbm.model = m.model_name
 where model in (select distinct model from ships_schema.ships)
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
,s_agg as 
(
select 
	model_name
	,model_id
	,cal.cbm_id
	,cal.cat
	,cal.sub_cat
	,cal.wm_cal_id
	,cal.wm_week
	,cal.wm_quarter
	,cal.wm_year
	,cal.wm_date
	,total_units
	,current_wm_date
	,min(first_sale_week) over (partition by model_name) as first_sale_week
	,current_wm_week_seq
from cal
left join s_agg_1
on s_agg_1.model = cal.model_name
and s_agg_1.wm_date = cal.wm_date
where 1=1
)
,s_cum as 
(--finding the rolling last 4, last 12, and last 52 weeks of ships
select *
	--sum windows functions find the cumulated total for the last 1, 3, and last 12 months
    --if the month has sales, then proceed. 
    --jan 2019 will have 20 units, 2-19 will have 20 + units from current month. 
        --pretty much keeps adding for the 4 rows
	,case
		when total_units is not null
		then sum(total_units) over (partition by model_name order by wm_date rows 3 preceding)
		else null end as last_4_units
	--4 weeks in a month
	,case
		when total_units is null
		then null
		else sum(total_units) over (partition by model_name order by wm_date rows 11 preceding)
		end  as last_12_units
	--12 weeks in 3 months
	,case
		when total_units is null
		then null
		else sum(total_units) over (partition by model_name order by wm_date rows 51 preceding)
		end  as last_52_units
	--same logic except getting a count of each date. 
	,case
		when total_units is null
		then null
		else count(wm_date) over (partition by model_name order by wm_date rows 3 preceding)
		end  as last_4_weeks
	,case
		when total_units is null
		then null
		else count(wm_date) over (partition by model_name order by wm_date rows 11 preceding)
		end  as last_12_weeks
	,case
		when total_units is null
		then null
		else count(wm_date) over (partition by model_name order by wm_date rows 51 preceding)
		end  as last_52_weeks
from s_agg
where first_sale_week <=wm_date -- don't want dates before the model ever made sales
and -- removes records when the model didn't have any ships for the month
case
	when wm_date <current_wm_date and total_units is null
	then 1
	else 0
	end = 0
)
,s_avg as  -- ships average
(-- using the window functioned aggregates to find the average monthly ships 
select *
	,(last_4_units/ last_4_weeks)::numeric(10,0) as last_4
	,(last_12_units / last_12_weeks)::numeric(10,0) as last_12
	,(last_52_units / last_52_weeks)::numeric(10,0) as last_52
    --creates weights for doing weighted average later
	,.2 as l52_weight
	,.5 as l4_weight
	,.3 as l12_weight
from s_cum
)
,s_adj as 
(
select
	model_name
	,model_id
	,cbm_id
    ,cat
    ,sub_cat
	,wm_cal_id
	,wm_date
	,wm_year
	,wm_quarter
	,total_units
	,last_52_units
	,wm_week
	,last_4
	,last_12
	,last_52
	,l4_weight
	,l12_weight
	,l52_weight
    --based on how the ams columns compare, we adjust the weights.
    --if two columns are more similar than another, those 2 get higher weights
	,case when last_4 *2 >= last_52 then l4_weight -.1
		when last_4 * 1.5 >= last_12 then l4_weight -.1
		when last_4 *2 <=last_52 and  last_4 *1.5 <=last_12 then l4_weight +.2
		when last_4 * 2 <= last_52 then l4_weight +.1
		when last_4 * 1.5 <= last_12 then l4_weight +.1
		else l4_weight end as l4_weight_adj
	,case when last_4 *2 >= last_52 then l12_weight
		when last_4 *1.5 >= last_12 then l12_weight +.1
		when last_4 *1.5 <=last_12 then l12_weight -.1
		else l12_weight end as l12_weight_adj
	,case when last_4 *2 <= last_52 and last_4 *1.5 >= last_12 then l52_weight +.1
		when last_4 *2 >= last_52 then l52_weight +.1
		when last_4 *2 <=last_52 then l52_weight -.1
		else l52_weight end as l52_weight_adj
	,current_wm_week_seq
	,current_wm_date
from s_avg
order by wm_date
)
,s_ams as --ships average monthly ships
(-- using the weights and ams to create the final ams
select
*
,coalesce(-- applying different weights to find the average monthly ships
	(last_4 * l4_weight_adj) + (last_12 * l12_weight_adj) + (last_52 * l52_weight_adj )
	,(last_4 *l4_weight) + (last_12 * l12_weight) + (last_52 * l52_weight)
	,(last_12 * .7) + (last_52 * .3)	
	) as ams_ships 
from s_adj
)
,s_proj as  -- ships projected 
( -- find the projected ams for the months following the current 
--for dates past the current month, the projected_ams column will be assigned
select *
	,avg(ams_ships) 
		over (partition by model_name, wm_week order by wm_date rows 1 preceding) 
	as projected_ams
	--^finds the average AMS for the weighted average
	,case
		when total_units is null
		then sum(total_units) over (partition by model_name, wm_week order by wm_date rows 1 preceding)
		else null
		end as most_current_total_units
	--when 'total units' is null, function applies the most recent sales by wm week.
	-- 2025 week 40 gets 2024 week 40's total
from s_ams
)
select 
	model_name
	,model_id
	,cbm_id
    ,cat
    ,sub_cat
	,wm_cal_id
	,wm_week
	,wm_quarter
	,wm_year
	,wm_date
	,total_units
	,cast(coalesce(ams_ships, projected_ams) as numeric(10,0)) as ams_ships
    --^choose the ams we created. if day is past current, the projected will take place
	,current_wm_week_seq
    ,most_current_total_units
from s_proj
-- where wm_date >=current_wm_date
where wm_date >=202545
)
;