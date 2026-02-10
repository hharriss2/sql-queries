--a view to look at the current item statuses for the intenral dorel catalog
create or replace view lookups.internal_item_status_view as 
(
with t1 as 
(
select distinct model
	,coalesce(item_status, item_status_overwrite) as item_status
	,updated_on
	,max(updated_on) over (partition by model) as latest_update_date --some items duplicate, finding the latest update for a model
from components.dorel_catalog
)
select model
	,item_status
	,dis.status_id
from t1
JOIN dim_sources.dim_item_status_3p dis 
ON t1.item_status = dis.status_name
where updated_on = latest_update_date
)