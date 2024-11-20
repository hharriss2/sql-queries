--sometimes models get put under new item id's. this will find the most recent instance of a model
create or replace view clean_data.current_wm_catalog_3p as 
(

with w as 
(
select item_id
	,model
	,upc
	,product_name
	,inserted_at
	,max(inserted_at) over (partition by model) as most_recent_time
    ,item_status
from clean_data.wm_catalog_3p
)
select item_id
	,model
	,upc
	,product_name
    ,item_status
from w
where inserted_at = most_recent_time

)
;