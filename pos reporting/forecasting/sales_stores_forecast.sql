--wm forceast for eccomm
with cam as --category account manager
( -- find the category and account manager 
select c.category_name
	,am.account_manager
from category c 
left join account_manager am 
on c.am_id= am.account_manager_id
)
,rs as --retail sales
( --ecomm total sales by wm week by cateogyr, account manager, and wm week
select 
	wm_week
	,cat
	,cam.account_manager
	,sum(sales) as total_sales
from pos_reporting.wm_com_pos tc -- materialized view needs to be refreshed before using
left join cam
on tc.cat = cam.category_name
where wm_week >=202501 -- earliest week we want to see in the forecast
group by wm_week, cam.account_manager, cat
)
,wmcal as 
(
select distinct wm_date::integer as wm_week
	,cam.category_name
	,account_manager
from wm_calendar wmc
left join  cam
on 1=1
where wm_date::integer >=202501
and wm_date::integer <=202526 -- latest week we want to go through in the forecast
order by category_name, wm_week
)
select distinct
	row_number() over (order by w.account_manager, category_name, w.wm_week) as sort_rows
	,w.wm_week
	,w.category_name
	,total_sales
	,w.account_manager
from wmcal w
left join rs
on w.wm_week = rs.wm_week
and w.category_name = rs.cat
order by w.account_manager, category_name, w.wm_week
;
