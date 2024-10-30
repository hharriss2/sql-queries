--finding the average monthly ships by looking at the last 4, last 12, and last 52 weeks shipped
create or replace view projections.last_ships as 
(
with s as  --ships
( -- find the total units sold by model by wm week
select
	model
	,sum(units) as total_units
	,date_trunc('month',date_shipped)::date as month_shipped
from ships_schema.ships s 
where 1=1
--and date_shipped >=current_date - interval '14 months'
and retailer ='Walmart.com'
and sale_type = 'Drop Ship'
and date_trunc('month',date_shipped)::date != date_trunc('month',current_date)::date -- getting full sales for
-- and s.model = '8620335WCOM' -- testing a model
group by model,date_trunc('month',date_shipped)::date

)
,cal_1 as --calendar step 1
( -- finding the month for calendar
--find the month/year and also just the month number
--calendar ends 12 months out
select distinct
	wcv.month_num
	,wcv.current_month_seq
	,date_trunc('month',wcv.date)::date as cal_month
	--^finds the current wm_date/week
from power_bi.wm_calendar_view wcv
where date <=current_date + interval '11 months'
)
,cal as --calendar table
( --assigns a date to every model
select model as model_name
	,m.model_id
    ,cat
    ,sub_cat
	,cbm_id
	,month_num
	,cal_month
	,current_month_seq
from cat_by_model cbm
join cal_1
on 1=1
join power_bi.dim_models m 
on cbm.model = m.model_name
where model in (select distinct model from ships_schema.ships)
-- and model = '8620335WCOM'

)

,s_agg_1 as --ships aggregate
( -- finding the total ships by model by month shipped
select
	model
	,month_shipped
	,total_units
from s
where 1=1 -- joining so every model gets the same amount of dates from CAL clause
order by month_shipped
)
,s_agg as 
(
select 
	model_name
	,model_id
	,cal.cbm_id
	,cal.cat
	,cal.sub_cat
	,cal.cal_month
	,cal.month_num
	,total_units
	,min(month_shipped) over (partition by model_name) as first_sale_month
	,current_month_seq
from cal
left join s_agg_1
on s_agg_1.model = cal.model_name
and cal.cal_month = s_agg_1.month_shipped
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
		then sum(total_units) over (partition by model_name order by cal_month rows 1 preceding)
		else null end as last_4_units
	--4 weeks in a month
	,case
		when total_units is null
		then null
		else sum(total_units) over (partition by model_name order by cal_month rows 2 preceding)
		end  as last_12_units
	--12 weeks in 3 months
	,case
		when total_units is null
		then null
		else sum(total_units) over (partition by model_name order by cal_month rows 11 preceding)
		end  as last_52_units
	--same logic except getting a count of each date. 
	,case
		when total_units is null
		then null
		else count(cal_month) over (partition by model_name order by cal_month rows 1 preceding)
		end  as last_4_weeks
	,case
		when total_units is null
		then null
		else count(cal_month) over (partition by model_name order by cal_month rows 2 preceding)
		end  as last_12_weeks
	,case
		when total_units is null
		then null
		else count(cal_month) over (partition by model_name order by cal_month rows 11 preceding)
		end  as last_52_weeks
from s_agg
where first_sale_month <=cal_month-- don't want dates before the model ever made sales
and -- removes records when the model didn't have any ships for the month
case
	when cal_month <date_trunc('month',current_date) and total_units is null
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
	,cal_month
	,month_num
	,current_month_seq
	,total_units
	,last_52_units
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
from s_avg
order by cal_month
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
		over (partition by model_name, month_num order by cal_month rows unbounded preceding) 
	as projected_ams
	--^finds the average AMS for the weighted average
	,case
		when total_units is null
		then sum(total_units) over (partition by model_name, month_num order by cal_month rows 1 preceding)
		else null
		end as most_current_total_units
	--when 'total units' is null, function applies the most recent sales by wm week.
from s_ams
)
select 
	model_name
	,model_id
	,cbm_id
    ,cat
    ,sub_cat
	,cal_month
	,month_num
	,total_units
	,cast(coalesce(ams_ships, projected_ams) as numeric(10,0)) as ams_ships
    --^choose the ams we created. if day is past current, the projected will take place
	,current_month_seq
    ,most_current_total_units
from s_proj
where cal_month >=date_trunc('month',current_date)
)
;
