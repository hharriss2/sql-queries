--first part of the pipeline for the stores_product_list table
--records ARE NOT unique. inserting will be distinct for item num & item id
    --do another distinct for related_item_num & item_id
create or replace view clean_data.stores_product_list_view as 
(
with ssa_s1 as  -- sales stores auto step 1
( -- find latest record of priem item nbr and upc matching
select distinct prime_item_nbr
	,prime_item_desc
	,ltrim(upc,'0') as upc_key -- removing leading 0's from upcs everywhere
	,max(daily) as latest_sale_date
from pos_reporting.store_sales
--where upc is not null
group by prime_item_nbr
	,prime_item_desc
	,ltrim(upc,'0')
)
,ssa_s2 as  --stpe 2 for sale store data
( -- sort data in case there are other prime item numbers 
select prime_item_nbr
	,upc_key
	,prime_item_desc
	,row_number() over (partition by prime_item_nbr order by latest_sale_date desc) as date_seq
from ssa_s1
)
, su as  -- sales upc
( -- find 1 prime item nbr for a upc relationship
select *
from ssa_s2
where date_seq= 1 -- removes duplicate item nums
)
,ms as  -- model tool
(  -- find the latest relationship for a model tool relationship
select * 
from clean_data.ships_model_tool_insert
)
,w as --wm catalog a
( -- find walmart item nums and their id's

select item_num
    ,item_id
    ,ltrim(gtin,'0') as gtin_key
    ,ltrim(upc,'0') as upc_key
from wm_catalog
)
,suw_s1 as -- sales walmart catalog step 1 
( -- join on the item numbers first
select
	su.prime_item_nbr
	,prime_item_desc
	,w.item_id
	,su.upc_key
from su
left join w
on su.prime_item_nbr = w.item_num
)
,suw as --sales and walmart catalog step 2 
(-- if the itme number join fails join on the upc key 
select distinct suw_s1.prime_item_nbr
	,coalesce(suw_s1.item_id , w.item_id) as item_id
	,prime_item_desc
	,coalesce(w.upc_key,suw_s1.upc_key) as upc_key
	,w.item_num as related_item_num
from suw_s1
left join w 
on suw_s1.upc_key = left(w.upc_key,length(w.upc_key) -1)
and suw_s1.item_id is null
)
,mcl as 
( -- bringing in the current catalog data 
    --by the time we refresh store products, the com should've been uploaded
    --meaning, item id's will have been updated with models. that item id info should be more reliable then finding item num stuff
select *
from clean_data.master_com_list

)
select suw.prime_item_nbr
	,coalesce(suw.item_id, mclin.store_item_id) as item_id -- if no item id found in suw, use the master list one that's found
	,case
		when mclid.product_name = ''
		then suw.prime_item_desc
		else coalesce(mclid.product_name,mclin.product_name,suw.prime_item_desc)
		end as prime_item_desc
	,suw.upc_key
	,suw.related_item_num
,coalesce(mclin.model,mclid.model) as model -- prioritizing best model
,coalesce(mclin.division, mclid.division) as division --prioritizing best division
from suw
left join mcl as mclid -- joining master com on item id
on mclid.item_id = suw.item_id::bigint
left join mcl as mclin --joining master com on item number
on mclin.item_id = suw.prime_item_nbr::bigint
)
;