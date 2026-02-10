create or replace view walmart.dim_sources.dim_calendar as 
( -- calendar view for power bi sources with extra columns such as YTD MTD for filtering in PBI's calculated measures
select
    id as cal_id
    ,date as cal_date
    ,date_part('day',date) as cal_day
    ,date_part('week',date) as cal_week
    ,date_part('month',date) as cal_month
    ,date_part('year',date) as cal_year
	--TO DATE METRICS
		--NOTE: MTD AND YTD are to YESTERDAY, not current date!!!
		--ex. feb 6 2026 is ytd right now, boolean will be 0 for today, 1 for feb 5
    ,case -- find the days leading up to the current date. for multiple year
		when date_part('month',date) = date_part('month',current_date)
		and date_part('day',date) < date_part('day',current_date)
		then 1 else 0 
		end as is_mtd_ey -- month to date every year
	,CASE
    WHEN TO_CHAR(date, 'MMDD') < TO_CHAR(CURRENT_DATE, 'MMDD')
    THEN 1
    ELSE 0
    END AS is_ytd_ey
    ,count(date) over (partition by date_trunc('month',date)) as total_days_in_month
from walmart.public.wm_calendar
order by cal_date
)
;
