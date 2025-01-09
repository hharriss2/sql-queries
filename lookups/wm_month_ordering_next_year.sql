--view will be used in the monthly forecast page for the power bi pipeline report
create or replace view lookups.wm_month_ordering_next_year as 
( -- for next years walmart calendar, order the months & how many weeks they have
with t1 as 
(
select
	date_trunc('month',date)::date as wm_month -- group the walmart date into a month
	,wm_week
	,count(date) as total_days -- counting the number of dates in the dataset. grouping by walmart weeks
from wm_calendar
where wm_year::integer = date_part('year',current_date) +1
group by date_trunc('month',date)::date, wm_week
)
select 
	wm_month -- group walmart dates into month
	,row_number() over ( order by wm_month) as month_seq -- provide a sequence for earliest to latest date
	,to_char(wm_month,'Month') as month_name --name of the month
	,sum(total_days) / 7 as week_average -- dividing by number of days in the wm week by 7 to get avg weeks for the month 
from t1
group by wm_month
)