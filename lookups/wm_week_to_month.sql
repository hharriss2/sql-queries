--assings the walmart week number to a specific month. 
--we'll use it to break out from month to weeks for sales team
create or replace view lookups.wm_week_to_month as 
(
select wm_date::integer as wm_date
	,min(wm_year::integer) as wm_year
	,min(date_part('month',date)) as first_month_num
from wm_calendar
where wm_week is not null
group by wm_week::integer,wm_year::integer
)
;
