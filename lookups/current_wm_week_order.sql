--used when forecasting wm weeks
--ex. power bi table where the first row is the current wm week.
	--join this table to calendar to assign a unique sequence number to order power bi
	-- sometimes week 53 won't be accounted for in the data set. if it's not,
		--coalesce(wm_week_seq, max(wm_week_seq) + 1
create or replace view lookups.current_wm_week_order as 
(
with wseq_1 as  -- step 1 for finding the walmart week order number
(
select distinct
	wm_date::integer as wm_date
	,wm_week::integer as wm_week
	,wm_year::integer as wm_year
	,max(case when date = current_date then wm_date::integer else null end) over ()
	as current_wm_date
from wm_calendar
)
,wseq_2 as 
(
select wm_week
	,row_number() over (order by wm_date)
	 wm_week_seq_1-- step 1 for wm sequence
from wseq_1
where wm_date >=current_wm_date
--202252


limit 53
)
select distinct
	wm_week
	,min(wm_week_seq_1) over (partition by wm_week) as wm_week_seq
		 
from wseq_2
)
;