--a view to look at the current item statuses for the intenral dorel catalog
create or replace view lookups.internal_item_status_view as 
(
with t1 as 
(
select distinct model
	,item_status
	,updated_on
	,max(updated_on) over (partition by model) as latest_update_date --some items duplicate, finding the latest update for a model
from components.dorel_catalog
)
select model
	,item_status
from t1
where updated_on = latest_update_date
)