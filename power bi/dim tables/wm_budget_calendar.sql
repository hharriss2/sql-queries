--calendar for the pos reporting & pos budget connecting
--find the sales related to the budget on a wm week basis
create or replace view power_bi.wm_budget_calendar as 
(

with cal as 
(
select
	min(id) as wm_cal_id
	,min(date) as first_wm_week_date
	,wm_week::integer as wm_week
	,wm_year::integer as wm_year
	,wm_date::integer as wm_date
	
from wm_calendar 

group by wm_week::integer
	,wm_year::integer
	,wm_date::integer
	)
,cal1 as --calendar step 1
( -- windows functions to get the next week date on a row
select *
	,lead(first_wm_week_date) over ( order by wm_cal_id) as next_week_date
from cal
)
,cal2 as --calendar ste 2
( -- identifies the current week
select * 
	,case
		when first_wm_week_date <= current_date and current_date <next_week_date
		then 1
		else 0 
		end as is_current_week
from cal1
)
select wm_cal_id
	,first_wm_week_date
	,wm_week
	,wm_year
	,wm_date
	,is_current_week
	,coalesce(
		lead(is_current_week) over (order by wm_cal_id)
		,0) as is_previous_week
from cal2
)