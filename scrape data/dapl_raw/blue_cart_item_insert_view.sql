--items from api call go into blue_cart_item_scrape
-- this view runs after to insert into the main scrape table, scrape_data.scrape_tbl
create or replace view dapl_raw.blue_cart_item_insert_view as 
(
with t1 as 
(
select 
item_id
,'https://www.walmart.com/ip/seort/' || item_id as url
,case
	when product_name is null
	then 'Product not Found'
	else product_name
	end as product_name
, manufacturer_name
,brand_name
,case
    when available = 'IN_STOCK'
    then true
    else false
    end as available
, num_of_images
, model_name
, category
, category_path
, upc
, num_of_variants
, price_retail
, price_was
, review_rating
, review_count
, seller_name
, description
,freight_shipping
,shipping_message
,base_id
,case
	when has_video = '{}'
	then false
	when has_video = '{"absolute pointer"}'
	then true
	else false 
	end as has_video
,case -- parsing through the display html to find the first display code
	when product_display_html ='[]' -- display codes with [] will be set to null
	then null
	else split_part(split_part(product_display_html,'>',2),'<',1) 
	end as display_code_1 --split part finds the first display code
,case
	when product_display_html = '[]'
	then null
	else split_part(
			split_part(
				split_part(product_display_html, ', <span',2) --see if there's text after the first display code
				,'>',2)
			,'<',1) -- finds the display code if there's any after the first product display 
	end as display_code_2
,case
	when shipping_message not like '%$%'
	then 0::numeric(10,2)
	else cast(
    split_part(
        split_part(shipping_message,',',1)
        ,'$',2) 
     as numeric(10,2)
    )end
     as shipping_cost
,case -- parsing the shipping message out correctly
	when shipping_message like '%by today%'
	then inserted_at::date
	when shipping_message like '%by tomorrow%'
	then cast(inserted_at::date + interval '1 days' as date)
	when shipping_message like '%product may be restricted%'
	then null
	else 
	 cast(to_date
	(
	split_part(
		split_part(shipping_message,', ',3)
		,' to',1) || ' 2024'
	,'MON DD YYYY') as date)
	end 
    as shipping_date
	,inserted_at::date
    as date_inserted
    ,inserted_at
	,color
from dapl_raw.blue_cart_item_scrape
)
select 
item_id
,url
,product_name
,manufacturer_name
,brand_name
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
,seller_name
,description
,freight_shipping
,shipping_message
,base_id
,has_video
,display_code_1
,case
	when display_code_2 = ''
	then null
	else display_code_2
	end as display_code_2
,shipping_cost
,shipping_date
,shipping_date - date_inserted  as est_days_shipped
,case
	when shipping_date - date_inserted <=2
	then true
	else false
	end as two_day_shipping
,date_inserted
,color
from t1
where inserted_at = (select max(inserted_at) from t1)

)
;
