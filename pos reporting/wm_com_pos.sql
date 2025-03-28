--powers the ecomm sales data for power bi reporting. 
--a look into retail sales with all the cats, groups, etc. added
create or replace view pos_reporting.wm_com_pos as 
(
with  rs AS --retail sales
(
SELECT 
    id
    ,tool_id::bigint as item_id
    ,product_name
    ,upc
    ,base_upc
    ,brand_name
    ,item_type
    ,sale_date
    ,wm_week
    ,units
    ,sales
    ,is_put
    ,2 as retail_type_id
FROM pos_reporting.retail_sales
)
,mcl as --master com list
(
select * 
from clean_data.master_com_list
)
,g as --group ids
(
select * 
from  group_ids
)
,cbm as --cat by model
(
select * 
from cat_by_model
)
,wmcal as --walmart calendar
(
select * 
FROM power_bi.wm_calendar_view
)
,cbid as --current base id
(
select base_id
    ,group_id
from lookups.current_base_id
)
,pfilter as 
(
select * 
from power_bi.promo_funding_pos_filter
)
,ac as --account manager category
(
select *
from account_manager_cat
)
,iinv as --internal inventory. inventory dorel has
(
select
	model
	,sum(quantity_on_hand) as quantity_on_hand
	,sum(open_order_quantity) as open_order_quantity
	,sum(po_quantity) as po_quantity
from inventory.sf_item_inventory
group by model
)
,eif as --ecomm inventory feeds 
( -- feeds from dorel that show the ecommerce inventory feeds
select
	model
	,sum(feed_quantity) as feed_quantity
from inventory.sf_ecomm_inventory_feeds
where 1=1
and retailer_name = 'Walmart.com'
group by model
)
select
    rs.id
    ,mcl.model
    ,mcl.division
    ,coalesce(mcl.current_item_id, rs.item_id)::text as tool_id
    ,coalesce(mcl.product_name,rs.product_name) as product_name
    ,g.group_id_id
    ,cbm.cat
    ,cbm.cbm_id
    ,coalesce(cbid.base_id,mcl.current_item_id, rs.item_id)::bigint as base_id
    ,rs.sale_date
    ,rs.wm_week
    ,coalesce(mcl.brand_name, rs.brand_name) as brand_name
    ,rs.base_upc
    ,rs.item_type
    ,rs.units
    ,rs.sales
    ,rs.is_put
    ,ac.account_manager
    ,ac.account_manager_id
    ,ac.category_id
    ,g.group_id
    ,g.collection_name
    ,cbm.sub_cat
    ,mcl.is_scrape_product_name
    ,case
    when item_type = 'Owned'
    then 1
    when item_type = 'DSV'
    then 2
    when item_type = '3P'
    then 4
    else null
    end as item_type_id
    ,mcl.is_top_100_item
    ,rs.retail_type_id
    ,iinv.quantity_on_hand
    ,iinv.open_order_quantity
    ,iinv.po_quantity
    ,eif.feed_quantity
    ,mcl.retail_type_assignment
from rs
left join mcl
on rs.item_id = mcl.item_id
left join cbm
on mcl.model = cbm.model
left join ac
on cbm.cat = ac.category_name
left join g
on rs.item_id = g.tool_id
left join cbid
on g.group_id = cbid.group_id
left join iinv
on mcl.model = iinv.model
left join eif
on mcl.model = eif.model
)
;


