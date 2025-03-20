create or replace view pos_reporting.wm_stores_pos as 
(
with ssa as  -- sales stores auto. wm retail pos
(
select ss.*
    ,1 as retail_type_id
    ,iss.item_status
    ,iss.item_stat_id
from pos_reporting.store_sales ss
left join lookups.item_status_store iss
on ss.prime_item_nbr = iss.item_num
)
,mcl as --master com list
(
select *
from clean_data.master_com_list
)
,cbm as --cat by model
(
select * 
from cat_by_model
)
,ca as --category account manager
(
select * 
from account_manager_cat
)
,g as --group id
(
select * 
from group_ids
)
,istat as --item status
(
select * 
from lookups.item_status_store
)
,sia as  -- store inventory aggregate
( -- dataset is store inventory by store number. this clause aggregates it to the item level
select
	all_links_item_number
    ,business_date
	,sum(store_in_transit_quantity_this_year) as store_in_transit_quantity_this_year
	,sum(store_in_warehouse_quantity_this_year) as store_in_warehouse_quantity_this_year
	,sum(store_on_hand_quantity_this_year) as store_on_hand_quantity_this_year
	,sum(store_on_order_quantity_this_year) as store_on_order_quantity_this_year
	,sum(traited_store_count_this_year) as traited_store_count_this_year
from inventory.wm_store_on_hands
where business_date = (select max(business_date) from inventory.wm_store_on_hands)
--^ use the inventory levels from today
group by all_links_item_number
    ,business_date
)
,si as --store inventory
(
select *
	,+store_in_warehouse_quantity_this_year
	+store_on_hand_quantity_this_year
	+store_on_order_quantity_this_year as stores_on_hand
from sia
)
,details as 
( -- initial joins before adding inventory
    --didn't want to have joins with coalesce, so seperating out for cleaner reading
select 
    ssa.id
    ,ssa.pos_qty
    ,ssa.pos_sales
    ,ssa.curr_repl_instock
    ,ssa.daily as sale_date
    ,coalesce(mcl.current_item_id, ssa.prime_item_nbr) as item_id
    ,cbm.cbm_id
    ,ca.account_manager_id as am_id
    ,mcl.division
    ,ssa.retail_type_id
    ,coalesce(mcl.product_name, ssa.prime_item_desc) as product_name
    ,mcl.model
    ,mcl.store_item_id as base_id
    ,mcl.brand_name
    ,ssa.item_stat_id
    ,ssa.item_status
    ,cbm.cat
    ,cbm.sub_cat
    ,ca.account_manager
    ,ca.category_id
    ,g.group_id
    ,g.group_id_id
    ,g.collection_name
    ,mcl.is_lookup_update
    ,mcl.is_scrape_product_name
    ,mcl.is_top_100_item
    ,mcl.retail_type_assignment
from ssa
left join mcl
on ssa.prime_item_nbr = mcl.item_id
left join cbm
on cbm.model = mcl.model
left join ca
on cbm.cat = ca.category_name
left join g g
on mcl.item_id = g.tool_id
)
select 
    id
    ,pos_qty
    ,pos_sales
    ,curr_repl_instock
    ,sale_date
    ,item_id
    ,cbm_id
    ,am_id
    ,division
    ,retail_type_id
    ,product_name
    ,model
    ,base_id
    ,brand_name
    ,item_stat_id
    ,item_status
    ,cat
    ,sub_cat
    ,account_manager
    ,category_id
    ,group_id
    ,group_id_id
    ,collection_name
    ,is_lookup_update
    ,is_scrape_product_name
    ,is_top_100_item
    ,si.store_in_transit_quantity_this_year
    ,si.store_in_warehouse_quantity_this_year
    ,si.store_on_hand_quantity_this_year
    ,si.store_on_order_quantity_this_year
    ,si.stores_on_hand
    ,si.traited_store_count_this_year
    ,retail_type_assignment
from details
left join si
on details.item_id = si.all_links_item_number 
and details.sale_date = si.business_date
)
;