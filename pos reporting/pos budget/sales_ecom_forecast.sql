--query that creates a template for the slales team to enter their .COM budget/forecast
--wm forceast for eccomm
with cam as --category account manager
( -- find the category and account manager 
select category_name
	,account_manager
	,am.category_id 
	,am.account_manager_id
from  account_manager_cat am 
where category_name in (select category_name from pos_reporting.wm_pos_budget_view)
)
,rs as --retail sales
( --ecomm total sales by wm week by cateogyr, account manager, and wm week
select 
	wm_week
	,cat
	,cam.category_id
	,cam.account_manager
	,cam.account_manager_id
	,sum(sales) as total_sales
from pos_reporting.wm_com_pos tc -- materialized view needs to be refreshed before using
left join cam
on tc.cat = cam.category_name
where wm_week >=202601 -- earliest week we want to see in the forecast
group by wm_week, cam.account_manager, cat,cam.account_manager_id,cam.category_id
)
,wmcal as 
(
select distinct wm_date::integer as wm_week
	,cam.category_name
	,account_manager
	,account_manager_id
	,cam.category_id
from wm_calendar wmc
left join  cam
on 1=1
where wm_date::integer >=202601
and wm_date::integer <=202653 -- latest week we want to go through in the forecast
order by category_name, wm_week,account_manager_id,category_id
)
,ws as --weekly sales
(-- clause gets sales info, category & account manager
select distinct
	row_number() over (order by w.account_manager, category_name, w.wm_week) as sort_rows
	,w.wm_week
	,w.category_name
	,w.category_id
	,total_sales
	,lag(total_sales) over (partition by category_name order by w.account_manager, category_name, w.wm_week) as prev_sales
	,w.account_manager
	,w.account_manager_id
from wmcal w
left join rs
on w.wm_week = rs.wm_week
and w.category_name = rs.cat
order by w.account_manager, category_name, w.wm_week
)

,wf as --weekly forecast
(--brings in the current forecast an account manager has for wm weeks
select 
	wm_date
	,category_name
	,account_manager
	,category_id
	,account_manager_id
	,forecast_sales
from pos_reporting.wm_pos_budget_view
where is_latest_budget_version =1
and retail_type_id = 2

)
select ws.sort_rows
	,ws.wm_week
	,ws.category_name
	,ws.total_sales
	,wf.forecast_sales
	,ws.total_sales -ws.prev_sales as wow_diff
	,ws.account_manager
from ws
left join wf
on ws.wm_week = wf.wm_date
and ws.category_id = wf.category_id
and ws.account_manager_id = wf.account_manager_id
order by sort_rows
;
