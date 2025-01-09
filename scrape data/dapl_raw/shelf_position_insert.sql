--inserts the shelf position data into scrape_data.shelf_position
create or replace view dapl_raw.shelf_position_insert as 
(
with sa as  -- search api 
(
select * 
from dapl_raw.blue_cart_search_api sa 
)
,sam as 
(
select request_type, request_term, max(inserted_at) as date_compare
from sa
group by request_type, request_term
)
,id as --item ids
(
select * 
from dim_sources.dim_wm_item_id
)
,mrs as 
(
select * 
from scrape_data.most_recent_scrape
)
select
	sa.request_type
	,coalesce(cl.category_name,sa.request_term) as request_term
	,sa.shelf_position
	,sa.page_number
	,sa.product_name
	,sa.item_id
	,sa.review_rating
	,sa.review_count
	,sa.is_sponsored
	,sa.price_retail
	,sa.price_was
	,sa.seller_name
    ,sa.inserted_at
    ,sa.inserted_at::date as date_inserted
	-- ,coalesce(is_internal_item, false) as is_internal_item	
from sa
left join sam
on sa.request_term = sam.request_term
and sa.request_type = sam.request_type
and sa.inserted_at = sam.date_compare
-- left join id 
-- on sa.item_id = id.item_id
left join dapl_raw.blue_cart_category_lookup cl
on sa.request_term = cl.category_id
where sam.date_compare is not null
)
;