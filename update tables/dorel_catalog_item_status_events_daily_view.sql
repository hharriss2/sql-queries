--looks at the previous catalog uploaded from snowflake to the most recent one
--with this view, we can add the 'previous status & status change date' to the components.dorel_catalog table
--also, can add the change log to the components.dorel_catalog_item_status_event table

create or replace view dapl_raw.dorel_catalog_item_status_events_daily_view as 
(
with ns as --new status
(select
	model
	,model||'-'||retailer_id as model_retailer_id
	,item_status as new_item_status
	,now() as item_status_change_date
from dapl_raw.products_raw
)
select
	dc.model
	,dc.model_retailer_id
	,ns.new_item_status
	,dc.item_status as prev_item_status
	,ns.item_status_change_date
from components.dorel_catalog dc
join ns
on dc.model_retailer_id = ns.model_retailer_id
where item_status !=new_item_status
)
;