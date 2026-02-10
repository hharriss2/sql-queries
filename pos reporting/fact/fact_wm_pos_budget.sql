--fact table for the pos reporting table
--wm fact table & this table will connect to the wm_budget_calendar table 
create or replace view power_bi.fact_wm_pos_budget as 
(
with rs as 
(
select
	wm_week
	,category_id
	,sum(sales) as ecom_sales
	,2 as retail_type_id
from pos_reporting.wm_com_pos
where wm_week >=202601 and wm_week <=202652
group by wm_week, category_id
)
,ss as 
(
select cal.wm_date::integer as wm_date
	,category_id
	,sum(pos_sales) as stores_sales
	,1 as retail_type_id
from pos_reporting.wm_stores_pos ws
join wm_calendar cal
on ws.sale_date = cal.date
where wm_date::integer >=202601 and wm_date::integer <=202652
group by cal.wm_date ,category_id
)
select  
	wb.wm_cal_id
	,wb.category_id
	,wb.account_manager_id
	,cast(forecast_sales as numeric(10,2)) as forecast_sales
	,wb.retail_type_id
	,inserted_at
	,budget_version
	,is_latest_budget_version
from pos_reporting.wm_pos_budget_view wb
left join rs 
on wb.wm_date = rs.wm_week
and wb.category_id = rs.category_id
and wb.retail_type_id = rs.retail_type_id
left join ss
on wb.wm_date = ss.wm_date
and wb.category_id = ss.category_id
and wb.retail_type_id = ss.retail_type_id
where 1=1
and wb.wm_date >=202601
)
;