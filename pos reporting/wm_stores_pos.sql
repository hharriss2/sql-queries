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
;