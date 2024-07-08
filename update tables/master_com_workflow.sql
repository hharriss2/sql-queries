--step 1: upsert data into com product list
INSERT INTO clean_data.com_product_list (item_id, model, division,product_name,is_scrape_product_name) 
    select item_id, model_name, division_name,product_name,is_scrape_product_name
    from clean_data.retail_com_model_tool_insert mti
    ON CONFLICT(item_id) 
    DO UPDATE SET
        model = EXCLUDED.model,
        division = EXCLUDED.division,
        product_name = EXCLUDED.product_name,
        is_scrape_product_name = excluded.is_scrape_product_name
    ;
--step 2: upsert the cleaned up com product list into master com 
insert into clean_data.master_com_list (item_id, model, division, product_name, is_scrape_product_name,retailer_type_id)
    select item_id, model, division_name,product_name,is_scrape_product_name,retailer_type_id
    from clean_data.com_to_master_com_insert
    on conflict(item_id)
    do update set
        model = excluded.model
        ,division = excluded.division
        ,product_name = excluded.product_name
        ,is_scrape_product_name = excluded.is_scrape_product_name
        ,retailer_type_id = excluded.retailer_type_id
        ;
--step 3: update the tool id brand names for Ecomm items
    --updating ecomm ones based off of the item id
update clean_data.master_com_list t1
set brand_name = t2.brand_name
from lookups.tool_brand t2
where t1.item_id = t2.tool_id::bigint
;
    --updating store items based off store_item_id
update clean_data.master_com_list t1
set brand_name = t2.brand_name
from lookups.tool_brand t2
where t1.store_item_id = t2.tool_id::bigint
;
--step 4: overwrite the master com info with what's in the lookup_com list
insert into clean_data.master_com_list (item_id, model, division, product_name, current_item_id,brand_name,retailer_type_id,is_lookup_update)
    select item_id, model, division, product_name, current_item_id,brand_name,retailer_type_id,is_lookup_update
    from clean_data.lookup_com_to_master_insert
    on conflict(item_id)
    do update set
     model = excluded.model
     ,division = excluded.division
     ,product_name = excluded.product_name
     ,current_item_id = excluded.current_item_id
     ,brand_name = excluded.brand_name
     ,retailer_type_id = excluded.retailer_type_id
     ,is_lookup_update = excluded.is_lookup_update
     ;
--step 5: update the stores product list
    --add in new item numbers into stores list
    --keep the product names but update everything else for an item
insert into clean_data.stores_product_list
	(item_num, item_id, model, product_name, division, upc)
select distinct 
	prime_item_nbr
	,item_id
	,model
	,prime_item_desc
	,division
	,upc_key
from clean_data.stores_product_list_view
on conflict (item_num)
do update set
model = excluded.model
,division = excluded.division
,item_id = excluded.item_id
,upc = excluded.upc
;
    --next, do the same as above, except using the 'related item num' id
insert into clean_data.stores_product_list
	(item_num, item_id, model, product_name, division, upc)
select distinct 
	related_item_num
	,item_id
	,model
	,prime_item_desc
	,division
	,upc_key
from clean_data.stores_product_list_view
where related_item_num is not null
on conflict (item_num)
do update set
model = excluded.model
,division = excluded.division
,item_id = excluded.item_id
,upc = excluded.upc
;
--step 6: add in the store product list into the master com list
    --joining on item id's to keep the correct models , product name, divisions, etc.
insert into clean_data.master_com_list (
	item_id
	,store_item_id
	,model
	,division
	,product_name
	,brand_name
	,retailer_type_id
    ,is_scrape_product_name
    )
    select 	item_num
	,store_item_id
	,model
	,division
	,product_name
	,brand_name
	,retailer_type_id
    ,is_scrape_product_name
    from clean_data.stores_to_master_com_insert
    on conflict(item_id)
    do update set
    store_item_id = excluded.store_item_id
	,model = excluded.model
	,division = excluded.division
	,product_name = excluded.product_name
	,brand_name = excluded.brand_name
	,retailer_type_id = excluded.retailer_type_id
    ,is_scrape_product_name = excluded.is_scrape_product_name
    ;
--step 7: update the brand names 
--brand names should be as listed in the master com 
update clean_data.master_com_list
set brand_name = 'Queer Eye'
where product_name like '%Queer%'
;
update clean_data.master_com_list
set brand_name = 'Cosmo'
where product_name like '%CosmoLiving by Cosmopolitan%'
;
--stpe 8: update lookup stores into the master com list
    --the overwriting table for stores data that will go into com master list 
insert into clean_data.master_com_list (item_id,store_item_id, model, division, product_name, current_item_id,brand_name,retailer_type_id,is_lookup_update)
    select item_num,store_item_id, model, division, product_name, current_item_id,brand_name,retailer_type_id,is_lookup_update
    from clean_data.lookup_stores_to_master_insert
    on conflict(item_id)
    do update set
     model = excluded.model
     ,store_item_id = excluded.store_item_id
     ,division = excluded.division
     ,product_name = excluded.product_name
     ,current_item_id = excluded.current_item_id
     ,brand_name = excluded.brand_name
     ,retailer_type_id = excluded.retailer_type_id
     ,is_lookup_update = excluded.is_lookup_update
     ;