--similar to the last_ships.sql query
--finds the mom% for each category.
--the mom% averages based on other months. ex jan 2019 averages with jan 2020
-- the % change will apply to the AMS from last_ships later on. 
create or replace view projections.sub_cat_lift as 
(
with r as  --retail sales
( -- first, find the total units sold for each sub category by month-year
select 
	sub_cat
	,date_trunc('month',sale_date)::date as month_year
	,date_part('year',sale_date) as sale_year
	,date_part('month',sale_date) as sale_month
	--grouping by year month
	, sum(units) as total_units
	,min(date_trunc('month',sale_date))::date as first_sale_month
from pos_reporting.wm_com_pos
where units >0
and sale_date not between '2020-01-01' and '2020-12-31'
	-- and sub_cat like '%Fireplace TV Stands%'
group by sub_cat
	,date_trunc('month',sale_date)::date
	,date_part('year',sale_date)
	,date_part('month',sale_date)
)
,cal_1 as --calendar step 1
(
-- finding the month for calendar
--find the month/year and also just the month number
--calendar ends 12 months out
select distinct
	date_trunc('month',wcv.date)::date as cal_month
	,date_part('month',date) as month_num
from power_bi.wm_calendar_view wcv
where 1=1
and  date <=current_date + interval '11 months'
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
	,cal_month
	,month_num
from sc
join cal_1
on 1=1
-- where sub_cat = 'Fireplace TV Stands'
)
,r_1 as --step 1 for calculations
(
--finds previous units to use for mom(month over month) for sub cat units
--assigns credibility variable for the sub category variances
select cal.sub_cat
	,cal_month
	,sale_year
	,month_num
	,total_units
	,lag(total_units,1) over (partition by cal.sub_cat order by cal_month) as prev_units
from cal
left join r
on cal.sub_cat = r.sub_cat
and cal.cal_month = r.month_year
where 1=1

)
,r_2 as --step 2 
(--to find mom(month over month) for sub cat units
select 
	sub_cat
	,cal_month
	,month_num
	,cast( -- y2-y1/y1 (month over month formula)
		(total_units - prev_units)/ nullif(prev_units,0)::numeric(10,2)
		as numeric(10,2)
		) as month_over_month
from r_1
)
,r_3 as  -- retail step 3
( -- after finding mom, we want to find the avg and std dev for the sub cat & category
select 
	*
	--find std dev for the sub cat & month number
	,coalesce(stddev(month_over_month) over (partition by sub_cat, month_num),0) as month_std
	--find avg for sub cat & month number
	,avg(month_over_month) over (partition by sub_cat, month_num) as month_avg
from r_2
)
,details as  -- data before aggregating
(
--use avg() +- stdev() to find points within threshold of std dev
select
	sub_cat
	,cal_month
	,month_num
	,month_over_month
	,case -- assigns a '1' to any outliers of the average according to avg +-stdev
		when month_over_month <=month_avg +month_std
		and month_over_month >=month_avg - month_std
		then 0
        when month_over_month is null 
        then 0
		else 1
		end as is_mom_outlier
from r_3 
)

--final result. find sub cat and month over month
--the new mom_average:
	--find the average mom% for past momnths
	--if the mom% is an outliar, does not include when averaging
	--for the remaining nulls from mom outliers, take the average of all values
select
	sub_cat
	,cal_month
	,month_num
	,month_over_month
	,coalesce(
		avg(
			case
			when is_mom_outlier =1
			then null
			else month_over_month
			end
			)
			over (partition by sub_cat, month_num order by cal_month rows unbounded preceding)
		,avg(month_over_month)
			over (partition by sub_cat, month_num order by cal_month rows unbounded preceding)		
		 )::numeric(10,2) as mom_average -- average not including outliers
	,is_mom_outlier

from details
order by sub_cat, cal_month
)
;