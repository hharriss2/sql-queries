--fact table for the pos reporting table
--wm fact table & this table will connect to the wm_budget_calendar table 
create or replace view power_bi.fact_wm_pos_budget as 
(
with bud as --budget
( --first part for the fact table. Getting the budget version 
select
	wm_cal_id
	,category_id
	,account_manager_id
	,forecast_sales
	,retail_type_id
	,inserted_at
	,row_number() over (partition by wm_cal_id, category_id, account_manager_id, retail_type_id order by inserted_at ) as budget_version
	--^#'s the forecast inserted in by the sales person. 1 being the earliest itteration
--	,account_manager
--	,category_name
--	,retail_type
from pos_reporting.wm_pos_budget
)
select 
	wm_cal_id
	,category_id
	,account_manager_id
	,forecast_sales
	,retail_type_id
	,inserted_at
	,budget_version
	,case
		when budget_version = max(budget_version) over (partition by wm_cal_id, category_id, account_manager_id, retail_type_id) 
		then 1 -- 1 is true
		else 0 -- 0 is false
		end as is_latest_budget_version
from bud
)
;
