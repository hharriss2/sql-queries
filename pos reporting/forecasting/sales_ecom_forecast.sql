--forecasting wm pos store sales for sales team for their quarterly budget

with cam as --category account manager
(-- group together category and manager
select c.category_name
	,am.account_manager
from category c 
left join account_manager am 
on c.am_id= am.account_manager_id
)
,rs as -- retail sales
(  -- find the total sales for stores by wm week, category, and account manager
select 
	wm_date::integer as wm_week
	,cam.category_name
	,cam.account_manager
	,sum(pos_sales) as total_sales
from test_stores tc
left join wm_calendar w
on tc.sale_date = w.date
left join cat_by_model cbm
on tc.cbm_id = cbm.cbm_id
left join cam
on cbm.cat = cam.category_name
where wm_date::integer >=202501 -- has to be in wm year or greater
group by wm_date::integer, account_manager, category_name
)

,wmcal as 
(
select distinct wm_date::integer as wm_week
	,cam.category_name
	,account_manager
from wm_calendar wmc
left join cam
on 1=1
where wm_date::integer >=202501
and wm_date::integer <=202526 -- the last date for forecasting
order by category_name, wm_week
)
select distinct
	row_number() over (order by w.account_manager, w.category_name, w.wm_week) as sort_rows
	,w.wm_week
	,w.category_name
	,total_sales
	,w.account_manager
from wmcal w
left join rs
on w.wm_week = rs.wm_week
and w.category_name = rs.category_name
order by w.account_manager, w.category_name, w.wm_week
;
