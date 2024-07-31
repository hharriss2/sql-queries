
--query that creates a template for the slales team to enter their STORES budget/forecast
--forecasting wm pos store sales for sales team for their quarterly budget
with cam as --category account manager
(-- group together category and manager
select category_name
	,account_manager
	,category_id 
	,account_manager_id
from  account_manager_cat am 
where category_name in (select category_name from pos_reporting.wm_pos_budget_view)
)
,rs as -- retail sales
(  -- find the total sales for stores by wm week, category, and account manager
select 
	wm_date::integer as wm_week
	,cam.category_name
	,cam.account_manager
	,cam.category_id
	,cam.account_manager_id
	,sum(pos_sales) as total_sales
from pos_reporting.wm_stores_pos tc
left join wm_calendar w
on tc.sale_date = w.date
left join cat_by_model cbm
on tc.cbm_id = cbm.cbm_id
left join cam
on cbm.cat = cam.category_name
where wm_date::integer >=202501 -- has to be in wm year or greater
group by wm_date::integer, cam.account_manager, category_name,cam.account_manager_id,cam.category_id
)

,wmcal as 
(
select distinct wm_date::integer as wm_week
	,cam.category_name
	,account_manager
	,account_manager_id
	,cam.category_id
from wm_calendar wmc
left join cam
on 1=1
where wm_date::integer >=202501
and wm_date::integer <=202553 -- the last date for forecasting
order by category_name, wm_week,account_manager_id,category_id
)
,ws as --weekly sales
(
select distinct
	row_number() over (order by w.account_manager, w.category_name, w.wm_week) as sort_rows
	,w.wm_week
	,w.category_name
	,w.category_id
	,total_sales
	,w.account_manager
	,w.account_manager_id
	,lag(total_sales) over (partition by w.category_name order by w.account_manager, w.category_name, w.wm_week) as prev_sales
from wmcal w
left join rs
on w.wm_week = rs.wm_week
and w.category_name = rs.category_name
order by w.account_manager, w.category_name, w.wm_week
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
and retail_type_id =1
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
