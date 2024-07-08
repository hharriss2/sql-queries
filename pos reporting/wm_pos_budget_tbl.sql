create or replace table pos_reporting.wm_pos_budget as 
(
with wb as --walmart budget
(
select
	min(id) as wm_cal_id
	,min(date) as first_wm_week_date
	,wm_week::integer as wm_week
	,wm_year::integer as wm_year
	,wm_date::integer as wm_date
from wm_calendar 
where 1=1
and wm_year::integer= (select max(wm_year::integer) from wm_calendar where date = current_date) 
--^^ finds the current wm_year for todays date. that's what we'll go off of for the budget
group by wm_week::integer
	,wm_year::integer
	,wm_date::integer
)
select
	wm_cal_id 
	,first_wm_week_date
	,wm_date
	,tf.wm_week
	,c.category_name
	,a.account_manager
	,c.category_id
	,a.account_manager_id
	,tf.forecast_sales
	,tf.retail_type_id
	,case
		when retail_type_id = 2
		then 'Ecom'
		when retail_type_id = 1
		then 'Stores'
		end as retail_type
    ,now() as inserted_at
from staging_wm_pos_budget tf  -- table from google sheets to postgres
join wb
on tf.wm_week = wb.wm_week
left join category c 
on tf.category = c.category_name
left join account_manager a 
on c.am_id = a.account_manager_id
)
;
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