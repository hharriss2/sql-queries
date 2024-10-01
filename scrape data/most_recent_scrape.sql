--powers the buy box report on BV sharing workspace
--finds the most recent scrape for an item where the scraped data is found
create or replace view scrape_data.most_recent_scrape as 
(
with mi as 
(
select distinct item_id, max(date_inserted) date_inserted
from scrape_data.scrape_tbl
where 1=1
and date_inserted >= current_date - interval '30 days'
-- and product_name is not null -- omits any items that the scraper did not find
-- and product_name != 'Product not Found'
group by item_id
)
,md as --max date
(
select max(date_inserted) as max_date
from mi
)
select
	id
	,url
	,s.item_id
	,product_name
	,manufacturer_name
	,available
	,num_of_images
	,model_name
	,category
	,category_path
	,upc
	,num_of_variants
	,price_retail
	,price_was
	,review_rating
	,review_count
	,free_shipping
	,two_day_shipping
	,shelf_position
	,est_days_shipped
	,enabled_freight_shipping
	,seller_name
	,base_id
	,description
	,inserted_at
	,s.date_inserted
	,price_display_code
	,has_video
	,brand_name
	,shipping_cost
	,freight_shipping_date
	,price_display_code_2
    ,case
    when s.date_inserted = md.max_date
    then 1 
    else 0
    end as is_today_scrape
    ,color
from scrape_data.scrape_tbl s
join mi 
on s.item_id = mi.item_id
and mi.date_inserted = s.date_inserted
left join md
on 1=1
)
;