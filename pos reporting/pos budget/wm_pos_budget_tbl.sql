create or replace view clean_data.wm_pos_budget_insert as 
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
--Need to change later as we add on to the walmart calendar
group by wm_week::integer
	,wm_year::integer
	,wm_date::integer
)
,details as 
(
select
	wm_cal_id 
	,first_wm_week_date
	,wm_date
	,wb.wm_week
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
on tf.wm_week = wb.wm_date
left join category c 
on tf.category = c.category_name
left join account_manager a 
on c.am_id = a.account_manager_id
)
select details.*
from details
--comparing to what's in the raw budget. if matching records exist, we'll exclude them so we don't oversaturate the budget versions
left join dapl_raw.wm_pos_budget wbr
on details.wm_cal_id = wbr.wm_cal_id
and details.category_id = wbr.category_id
and details.forecast_sales = wbr.forecast_sales
and details.retail_type_id = wbr.retail_type_id
and details.account_manager_id = wbr.account_manager_id
where wbr.wm_cal_id is null -- where record doesn't exist yet

)
;
/*insert for the budget*/
	insert into dapl_raw.wm_pos_budget
	(
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
	)
select wm_cal_id 
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
from clean_data.wm_pos_budget_insert
where forecast_sales is not null
;
