--sub cat part for projections
--it finds the month % change 2019 - 2022 ( compare 01-2019 to 02-2019, 02-2019 to 03-2019 etc)
--the % avg between all the years are averaged discluding 2020
create or replace view projections.sub_cat_change as 
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
from pos_reporting.wm_com_pos
where units >0
and sale_date not between '2020-01-01' and '2020-12-31'
--	and sub_cat like '%Baby Mat%'
group by sub_cat
	,date_trunc('month',sale_date)::date
	,date_part('year',sale_date)
	,date_part('month',sale_date)
)
,r_1 as --step 1 for calculations
(
--finds previous units to use for mom(month over month) for sub cat units
--assigns credibility variable for the sub category variances
select sub_cat
	,month_year
	,sale_year
	,sale_month
	,total_units
	,lag(total_units,1) over (partition by sub_cat order by month_year) as prev_units
from r
)
,r_2 as --step 2 
(--to find mom(month over month) for sub cat units
select 
	sub_cat
	,month_year
	,sale_year
	,sale_month
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
	,stddev(month_over_month) over (partition by sub_cat, sale_month) as month_std
	--find avg for sub cat & month number
	,avg(month_over_month) over (partition by sub_cat, sale_month) as month_avg
from r_2
)
,details as  -- data before aggregating
(
--use avg() +- stdev() to find points within threshold of std dev
select
	sub_cat
	,month_year
	,sale_year
	,sale_month
	,month_over_month
	,case -- assigns a '1' to any outliers of the average according to avg +-stdev
		when month_over_month <month_avg +month_std
		and month_over_month >month_avg - month_std
		then 0
		else 1
		end as is_mom_outlier
from r_3 
)
--final result. find sub cat and month over month
select
	sub_cat
	,sale_month::text as month_num
	,avg(
		case
		when is_mom_outlier =1
		then null
		else month_over_month
		end
	)::numeric(10,2) as mom_average -- average not including outliers
	,avg(month_over_month) as mom_average_original -- average including outliars
	,stddev(month_over_month)::numeric(10,2) as stddev_mom -- standard deviation for month over month 
from details
group by sub_cat, sale_month
)
;