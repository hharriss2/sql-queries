create table dapl_raw.forecast_dhp as 
(
select * 
from forecast_agenda_testing_py
)
;
create or replace view dapl_raw.forecast_dhp_insert_view as 
(
with fc as --forecast
( -- making change match the structure in forecast.forecast_dhp
select
	case
		when item_type = 'EWM' then 'DSV'
		when item_type = 'OWM' then 'Bulk'
		else null
		end as item_type
	,right(online_sku,length(online_sku) -2) as model
	,item_num as item_id
	,description as product_name
	,imp_code
	,priority_code
	,field_name
	,forecast_date
	,units
from dapl_raw.forecast_dhp
)
select fc.item_type
	,item_type_id
	,model
	,item_id
	,product_name
	,imp_code
	,imp_code_id
	,priority_code
	,priority_code_id
	,field_name
	,forecast_date
	,units
from fc -- bringing in id's from dim tables
left join power_bi.dim_item_type it
on fc.item_type = it.item_type
left join power_bi.dim_implimentation_code ic
on fc.imp_code = ic.imp_code_name
left join power_bi.dim_priority_code pc
on fc.priority_code = pc.priority_code_name
)
;

