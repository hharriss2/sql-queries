---similar to the lookups.current_wm_week_order
--if we're in month 10, it gets assigned a 1, month 9 gets assigned 12
    --bc order goes 10,11,12,1,2,3,4...&9 back to 10 
create or replace view lookups.current_month_order as 
(
with wseq_1 as  -- step 1 for finding the walmart week order number
(
select distinct
	date_trunc('month', date) as month_year
	,date_part('month', date) as month_num
	,max(case when date = current_date then date_trunc('month', date) else null end) over ()
	as current_month_year
from wm_calendar
)
,wseq_2 as 
(
select 
	month_num
	,row_number() over (order by month_year) as wm_month_seq_1
from wseq_1
where month_year >=current_month_year
--202252


)
select distinct
	month_num
	,min(wm_month_seq_1) over (partition by month_num) as month_seq
from wseq_2
)
;

