--calendar for the pos reporting & pos budget connecting
--find the sales related to the budget on a wm week basis
create view power_bi.wm_budget_calendar as 
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