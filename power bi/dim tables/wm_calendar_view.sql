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
,l4_wm_date as 
(
select distinct wm_date::integer as wm_date
from wm_calendar
where date <current_date
and date!=current_date
order by wm_date::integer desc limit 5
)
,l3_wm_date as 
(
select distinct wm_date::integer as wm_date
from wm_calendar
where date <current_date
and date!=current_date
order by wm_date::integer desc limit 4
)
,l13_wm_date as 
(
select distinct wm_date::integer as wm_date
from wm_calendar
where date < current_date
and date!=current_date
order by wm_date::integer desc limit 14
)
,l52_wm_date as 
(
select distinct wm_date::integer as wm_date
from wm_calendar
where date < current_date
and date!=current_date
order by wm_date::integer desc limit 53
)
,current_wm_date as 
(
select distinct wm_date::integer as wm_date
from wm_calendar
where date= current_date
)
,details as 
(
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
        	when max(case when current_date - interval '7 days'= date  then wm_date::integer else null end) over() = wm_date::integer
        	then 1 
        	else 0
        	end  as previous_wm_week
        ,case -- find the wm date a week ago, subtract 100 to make it last weeks for last year
        	when max(case when current_date - interval '7 days'= date  then wm_date::integer -100 else null end) over() 
        	= wm_date::integer 
        	then 1 
        	else 0
        	end  as previous_wm_week_ly
        ,case
            when wm_date::integer in (select wm_date from l4_wm_date)
            and wm_date::integer !=(select wm_date from current_wm_date)
            then 1
            else 0
            end as is_last_4_weeks
        ,case
            when wm_date::integer in (select wm_date from l3_wm_date)
            and wm_date::integer !=(select wm_date from current_wm_date)
            then 1
            else 0
            end as is_last_3_weeks
        ,case
            when wm_date::integer in (select wm_date from l13_wm_date)
            and wm_date::integer !=(select wm_date from current_wm_date)
            then 1
            else 0
            end as is_last_13_weeks
        ,case
            when wm_date::integer in (select wm_date from l52_wm_date)
            and wm_date::integer !=(select wm_date from current_wm_date)
            then 1
            else 0
            end as is_last_52_weeks
        ,case
            when wm_date::integer in (select wm_date -100 from l4_wm_date)
            and wm_date::integer !=(select wm_date -100 from current_wm_date)
            then 1
            else 0
            end as is_last_4_weeks_ly
        ,case
            when wm_date::integer in (select wm_date -100 from l13_wm_date)
            and wm_date::integer !=(select wm_date -100 from current_wm_date)
            then 1
            else 0
            end as is_last_13_weeks_ly
        ,case
            when wm_date::integer in (select wm_date -100 from l52_wm_date)
            and wm_date::integer !=(select wm_date -100 from current_wm_date)
            then 1
            else 0
            end as is_last_52_weeks_ly
        --finds the wm date before the current week
        ,case -- when the date is today, apply wm date to every row, then compare wm date
        	when max(case when current_date = date then wm_date::integer else null end) over() - 100 = wm_date::integer
        	then 1
        	else 0 
        	end as is_current_wm_week_ly
        ,case -- boolean if the rows wm_year is the current wm year
        	when max( case when current_date = date then wm_year else null end) over() = wm_year
        	then 1
        	else 0
        	end as current_wm_year
		,case -- boolean for the current wm years year to date by wm week
			when max( case when current_date = date then wm_year else null end) over() = wm_year
			and max(case when current_date = date then wm_date::integer else null end) over() >= wm_date::integer
			and date <=current_date - interval '1 day'
			then 1 
			else 0 
			end as is_ytd_wm_week
        ,case -- boolean for the ytd last years wm years year to date by wm week
			when max( case when current_date - interval '1 year' = date then wm_year else null end) over() = wm_year
			and max(case when current_date - interval '1 year' = date then wm_date::integer else null end) over() >= wm_date::integer
			and date <=current_date - interval '1 year 1 day'

			then 1 
			else 0 
			end as is_ytd_wm_week_ly
		,max(case when current_date = date then wm_date else null end) over () as current_wm_date

FROM wm_calendar w
left join wo
on w.wm_week::integer = wo.wm_week
left join mo 
on date_part('month',w.date) = mo.month_num
where 1=1
)
SELECT
    wmcal_id
    ,date
    ,wm_week
    ,wm_year
    ,wm_date
    ,month
    ,wm_quarter
    ,is_mtd_ey -- month to date every year
	,is_ytd_ey --year to date every year
	,current_wm_week_seq
    ,month_num
    ,current_month_seq
    ,wm_day_of_week 
    ,is_current_wm_week
	,previous_wm_week
    ,is_last_4_weeks
    ,is_current_wm_week_ly
    ,current_wm_year
	,is_ytd_wm_week
	,max(case when current_date = date then wm_day_of_week else null end) over() as current_wm_day_of_week
	,is_last_13_weeks
	,is_last_4_weeks_ly
	,is_last_13_weeks_ly
	,is_last_52_weeks
	,is_last_52_weeks_ly
	,previous_wm_week_ly
    ,is_ytd_wm_week_ly
    ,is_last_3_weeks
FROM details
where 1=1
-- and date <=current_date
-- order by date desc
);