--step 6 of the insert. the stores data will feed into the master com list 
    --joining on stores item id to master com item id to
    --this way finds the most recent .com item id info and gives it to the store item
        --ensures that item id info stays the same accross stores and .com
create or replace view clean_data.stores_to_master_com_insert as 
(
select 
	sl.item_num
	,coalesce(ml.model , sl.model) as model
	,coalesce(ml.division, sl.division) as division
	,coalesce(ml.product_name,sl.product_name) as product_name
	,sl.item_id::bigint as store_item_id
    ,1 as retailer_type_id
    ,ml.brand_name
    ,ml.is_scrape_product_name
from clean_data.stores_product_list sl
left join clean_data.master_com_list ml
on sl.item_id::bigint = ml.item_id
where 1=1
)
;
