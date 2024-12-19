--adding inventory levels to the projections tool

create or replace view projections.inventory_feed_com as 
(
select
	model
	,sum(feed_quantity) as total_feed
	,max(date_created) as latest_created_date
	,max(date_updated) as latest_updated_date
	,max(inserted_at) as inserted_at
from inventory.sf_ecomm_inventory_feeds
group by model
)
;