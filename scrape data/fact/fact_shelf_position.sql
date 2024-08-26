--for buy box report. adds an additional tab for shelf position scraped data
create or replace view power_bi.fact_shelf_position as 
(
with sa as  -- search api 
(
select * 
	,min(page_number) over (partition by item_id, request_term, request_type) as best_page_number_tw
from scrape_data.shelf_position
where date_inserted = current_date

)
,slw1 as --shelf last week step 1
(
select item_id
	,request_term
	,request_type
	,page_number::bigint as page_number
	,min(shelf_position) as best_shelf_position_lw
from scrape_data.shelf_position
where date_inserted = current_date - interval '7 days'
group by item_id,request_term,request_type,page_number
)
,slw2 as --shelf last week 2 
(
select 
	item_id
	,min(page_number) as min_page_num
from slw1
group by item_id
)
,slw as --shelf last week final
(
select slw1.*
from slw1
join slw2
on slw1.item_id = slw2.item_id
and slw1.page_number = slw2.min_page_num
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
	,sa.best_page_number_tw
	,slw.page_number as best_page_number_lw
	,slw.best_shelf_position_lw
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
		when sa.page_number = best_page_number_tw
		then true
		else false
		end as is_best_shelf
from sa
left join slw
on sa.item_id = slw.item_id
and sa.request_term = slw.request_term
and sa.request_type = slw.request_type
left join id 
on sa.item_id = id.item_id
left join dapl_raw.blue_cart_category_lookup cl
on sa.request_term = cl.category_id
left join mrs
on mrs.item_id = sa.item_id 

)
;