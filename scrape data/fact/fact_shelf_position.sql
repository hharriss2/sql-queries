--for buy box report. adds an additional tab for shelf position scraped data
create or replace view power_bi.fact_shelf_position as 
(
with sa as  -- search api 
(
select * 
from scrape_data.shelf_position
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
from power_bi.dim_wm_item_id
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
	,coalesce(sa.is_sponsored,false) as is_sponsored
	,sa.price_retail
	,sa.price_was
	,sa.seller_name
    ,sa.inserted_at
    ,sa.inserted_at::date as date_inserted
    ,mrs.num_of_images
    ,mrs.num_of_variants
    ,mrs.price_display_code
    ,mrs.price_display_code_2
	,coalesce(is_internal_item, false) as is_internal_item	
	,case
		when date_compare is null
		then false
		else true
		end as is_most_recent_scrape
		
from sa
left join sam
on sa.request_term = sam.request_term
and sa.request_type = sam.request_type
and sa.inserted_at = sam.date_compare
left join id 
on sa.item_id = id.item_id
left join dapl_raw.blue_cart_category_lookup cl
on sa.request_term = cl.category_id
left join mrs
on mrs.item_id = sa.item_id 
)
;