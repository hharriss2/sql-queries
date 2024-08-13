--main cleaned up view for the pos reporting table
create or replace view pos_reporting.wm_pos_budget_view as 
(
with bud as --budget
( --first part for the fact table. Getting the budget version 
select
	wm_cal_id 
	,first_wm_week_date
	,wm_date
	,wm_week
	,category_name
	,account_manager
	,category_id
	,account_manager_id
	,forecast_sales
	,retail_type_id
	,retail_type
	,inserted_at
	,row_number() over (partition by wm_cal_id, category_id, retail_type_id order by inserted_at desc) as budget_version
	--^#'s the forecast inserted in by the sales person. 1 being the earliest itteration
--	,account_manager
--	,category_name
--	,retail_type
from dapl_raw.wm_pos_budget
)
select 
	wm_cal_id 
	,first_wm_week_date
	,wm_date
	,wm_week
	,category_name
	,account_manager
	,category_id
	,account_manager_id
	,forecast_sales
	,retail_type_id
	,retail_type
	,inserted_at
	,dense_rank() over (order by budget_version desc) as budget_version --highest # means it's the latest version
	--if budget has same wm date, category, retailer, we take the latest version of that
	,case -- budget with 1 means it's the latest version. 
		when budget_version = min(budget_version) over (partition by wm_cal_id, category_id, retail_type_id) 
		then 1 -- 1 is true
		else 0 -- 0 is false
		end as is_latest_budget_version

from bud
)
;