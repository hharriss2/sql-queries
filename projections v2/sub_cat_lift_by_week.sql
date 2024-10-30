create or replace view projections.sub_cat_lift_by_week as 
(
with r as 
(
select 
	sub_cat
	,wm_week
	,sum(units) as total_units
from pos_reporting.wm_com_pos
where units >0
and sale_date not between '2020-01-01' and '2020-12-31'
	and sub_cat like '%Fireplace TV Stands%'
group by sub_cat
	,wm_week
)
,cal_1 as --calendar step 1
(
-- finding the month for calendar
--find the month/year and also just the month number
--calendar ends 12 months out
select distinct
	wcv.wm_date
	,wcv.wm_week
	,wm_year
	,wm_quarter
	,max(case when date = current_date then wm_date else null end) over() as current_wm_date 
	--^finds the current wm_date/week
from power_bi.wm_calendar_view wcv
where 1=1
and date <=current_date + interval '27 weeks'
and date not between '2020-01-01' and '2020-12-31' 
)
,sc as 
(
select distinct sub_cat
from cat_by_model
)
,cal as --calendar table
(
--assigns a date to every sub cat
select sub_cat
	,wm_date::integer as wm_date
	,wm_week
	,wm_year
from sc
join cal_1
on 1=1
where sub_cat = 'Fireplace TV Stands'
)
,r_1 as --step 1 for calculations
(
--finds previous units to use for wow(month over month) for sub cat units
--assigns credibility variable for the sub category variances
select cal.sub_cat
	,wm_date
	,wm_year
	,cal.wm_week
	,total_units
	,lag(total_units,1) over (partition by cal.sub_cat order by wm_date) as prev_units
from cal
left join r
on cal.sub_cat = r.sub_cat
and cal.wm_date = r.wm_week
where 1=1

)
,r_2 as --step 2 
(--to find wow(month over month) for sub cat units
select 
	sub_cat
	,wm_date
	,wm_week
	,cast( -- y2-y1/y1 (month over month formula)
		(total_units - prev_units)/ nullif(prev_units,0)::numeric(10,2)
		as numeric(10,2)
		) as week_over_week
from r_1
)
,r_3 as  -- retail step 3
( -- after finding wow, we want to find the avg and std dev for the sub cat & category
select 
	*
	--find std dev for the sub cat & month number
	,coalesce(stddev(week_over_week) over (partition by sub_cat, wm_week),0) as week_std
	--find avg for sub cat & month number
	,avg(week_over_week) over (partition by sub_cat, wm_week) as week_avg
from r_2
)
,details as  -- data before aggregating
(
--use avg() +- stdev() to find points within threshold of std dev
select
	sub_cat
	,wm_date
	,wm_week
	,week_over_week
	,case -- assigns a '1' to any outliers of the average according to avg +-stdev
		when week_over_week <=week_avg +week_std
		and week_over_week >=week_avg - week_std
		then 0
        when week_over_week is null 
        then 0
		else 1
		end as is_wow_outlier
from r_3 
)

--final result. find sub cat and month over month
--the new wow_average:
	--find the average wow% for past wownths
	--if the wow% is an outliar, does not include when averaging
	--for the remaining nulls from wow outliers, take the average of all values
select
	sub_cat
	,wm_date
	,wm_week
	,week_over_week
	,coalesce(
		avg(
			case
			when is_wow_outlier =1
			then null
			else week_over_week
			end
			)
			over (partition by sub_cat, wm_week order by wm_date rows unbounded preceding)
		,avg(week_over_week)
			over (partition by sub_cat, wm_week order by wm_date rows unbounded preceding)		
		 )::numeric(10,2) as wow_average -- average not including outliers
	,is_wow_outlier

from details
order by sub_cat, wm_date
)