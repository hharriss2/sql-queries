create or replace view dapl_raw.update_master_ships_color_brand_div as 
(
with t1 as
(
select distinct model
	,internal_item_name
	,division_name
	,item_color
	,brand_name
	,max(item_status_date) over (partition by model) as current_item_status
	,item_status_date
from components.dorel_catalog
)
select *
from t1
where  1=1
and item_status_date = current_item_status
)
;