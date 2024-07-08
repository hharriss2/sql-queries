--this view is used to upsert the lookup table into master com list for store items (retailer type id of 1)
--if data needds to be corrected on the fly, you can update the lookup_stores table and the records should overwrite the ones in POS Reporting on Power BI
create or replace view clean_data.lookup_stores_to_master_insert as 
(
with ls as --lookup stores
(
select
	prime_item_num
	,item_id
	,model
	,brand_name
	,division
	,item_description
	,date_inserted
	,current_item_num
from pos_reporting.lookup_stores
)
,lsm as --lookup stores max
(--find the max date on lookup stores to use the most current entry for an item
select 
	prime_item_num
	,max(date_inserted) as date_compare
from ls 
group by prime_item_num
)
,lsd as --lookup store details
( -- makes item nums unique by giving the most recent inserted record of the item num
select
	ls.prime_item_num
	,ls.item_id
	,ls.model
	,ls.brand_name
	,ls.division
	,ls.item_description
	,ls.current_item_num
	,1 as is_lookup_update
	,1 as retailer_type_id
from ls
join lsm
on ls.prime_item_num = lsm.prime_item_num
and ls.date_inserted = lsm.date_compare
)
,details as 
( -- joins the most recent item in the lookup with master com list
	--if there are any null values in the lookup, master com list will keep its value
	--otherwise, use the lookup value 
select 
	lsd.prime_item_num::bigint as item_num
	,coalesce(lsd.item_id, mcl.store_item_id) as store_item_id
	,coalesce(lsd.model,mcl.model) as model
	,coalesce(lsd.item_description, mcl.product_name) as product_name
	,coalesce(lsd.division,mcl.division) as division
	,coalesce(lsd.current_item_num::bigint, mcl.current_item_id) as current_item_id
	,coalesce(lsd.brand_name, mcl.brand_name) as brand_name
	,1 as retailer_type_id
	,1 as is_lookup_update
from lsd
left join clean_data.master_com_list mcl 
on lsd.prime_item_num::bigint = mcl.item_id
)
select * 
from details
)
;

