--view used for power bi reports
create or replace view power_bi.wm_calendar_view as (
with wo as --week order 
(
select * 
from lookups.current_wm_week_order
)
,mo as 
(
select * 
from lookups.current_month_order
)
SELECT
    id AS wmcal_id
    ,date
    ,w.wm_week
    ,wm_year
    ,wm_date
    ,COALESCE(wm_sale_month,
        CASE
            WHEN w.wm_week = '1'::text THEN 'February'::text
            ELSE btrim(to_char(date::timestamp with time zone, 'Month'::text))
        END) AS month
    ,wm_quarter
    ,case -- find the days leading up to the current date. for multiple year
		when date_part('month',date) = date_part('month',current_date)
		and date_part('day',date) <= date_part('day',current_date)
		then 1 else 0 
		end as is_mtd_ey -- month to date every year
	,case-- find months+days leading up to current date. for every year
		when date_part('month',date) <= date_part('month',current_date)
		and date_part('day',date) <= date_part('day',current_date)
		then 1
		when date_part('month',date) <= date_part('month',current_date)
		then 1 
		else 0 
		end as is_ytd_ey --year to date every year
		,case
			when w.wm_week is null 
			then null
			else coalesce(wm_week_seq, max(wm_week_seq) over ()+1)
			end as current_wm_week_seq
			--the current ordering of walmart week from the current then out 52
				--if it's week 40, order is 1. week 39 would be ordered last (52) 
				--week 53 is always labeled 53 if not present in the current calendar
        ,date_part('month',date) as month_num
        ,month_seq as current_month_seq
        ,dense_rank() over (partition by w.wm_date::integer order by date) as wm_day_of_week 
        -- ^order for the day of the week. saturday = 1
        ,case -- when the date is today, apply wm date to every row, then compare wm date
        	when max(case when current_date = date then wm_date else null end) over() = wm_date
        	then 1
        	else 0 
        	end as is_current_wm_week
        --^if the date is in the current wm week, then 1 else 0
        ,case -- take the wm date from a week ago and compare it to the wm date for each row
        	when max(case when current_date - interval '7 days'= date  then wm_date else null end) over() = wm_date
        	then 1 
        	else 0
        	end  as previous_wm_week
        ,case -- take the wm date from 4 weeks ago and compare it to every row
        	when max(case when current_date - interval '28 days' = date then wm_date else null end ) over() <=wm_date
        		and max(case when current_date = date then wm_date else null end) over() != wm_date
        		--^disclude the current wm date and only look at the past 4
        	then 1
        	else 0
        	end as is_last_4_weeks
        --finds the wm date before the current week
FROM wm_calendar w
left join wo
on w.wm_week::integer = wo.wm_week
left join mo 
on date_part('month',w.date) = mo.month_num
where 1=1
and date <=current_date
order by date desc
)