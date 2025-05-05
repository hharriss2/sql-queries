--base table for the laggers and gainers
--finds all of the sales for last 13 weeks for items
--from this table, we can create a few reports
    --top gainers for 1P & 3P
    --top laggers for 1P & 3P
create or replace view pos_reporting.laggers_gainers_base as 
(
with details_agg as 
(
select
	r.tool_id
	,mcl.model
	,coalesce(mcl.retail_type_assignment,3) as retail_type_assignment
	--2 is a ecomm, 3 is a 3p item
	,cbm.cat
	,cbm.sub_cat
	,amc.account_manager
	,g.group_id
	,mcl.division
	,coalesce(mcl.product_name,r.product_name) as product_name
	,sum( -- sum of units for last 4 weeks where the item isn't from 3P sales
		case
		when is_last_4_weeks = 1 and item_type !='3P'
		then units
		else 0
		end) as l4_units
	,sum(-- sum of units for last 13 weeks where the item isn't from 3P sales
		case
			when is_last_13_weeks = 1 and item_type !='3P'
			then units
			else 0
			end) as l13_units
	,sum( -- sum of l4w units for 3P
		case
		when is_last_4_weeks = 1 and item_type ='3P'
		then units
		else 0
		end) as l4_units_3p
	,sum( -- sum of l13w units for 3P
		case
			when is_last_13_weeks = 1 and item_type ='3P'
			then units
			else 0
			end) as l13_units_3p
from pos_reporting.retail_sales r 
join power_bi.wm_calendar_view w
on r.sale_date = w.date
and w.is_last_13_weeks = 1
left join clean_data.master_com_list mcl
on r.tool_id::bigint = mcl.item_id
left join cat_by_model cbm
on mcl.model = cbm.model
left join account_manager_cat amc
on cbm.cat = amc.category_name
left join group_ids g
on r.tool_id::bigint = g.tool_id
group by 
	r.tool_id
	,coalesce(mcl.retail_type_assignment,3)
	,mcl.model
	,mcl.division
	,cbm.cat
	,cbm.sub_cat
	,g.group_id
	,coalesce(mcl.product_name,r.product_name)
	,amc.account_manager
)
,igdetails as
( -- finds if item was on promo by wm dates
select * 
from clean_data.item_grouping_by_wm_week
)
,wdp as
( --finding all wm dates that are l4w or l13 weeks
select distinct wm_date::integer as wm_date
,is_last_4_weeks
,is_last_13_weeks
from power_bi.wm_calendar_view 
where is_last_13_weeks =1
and date <current_date
),promo as 
( --combinging the promo list and the wm dates to find items on promo in the last 13 weeks
select item_id
	,group_name
	,max(wm_start_date) as wm_start_date
	,max(wm_end_date) as wm_end_date
	,max(wdp.is_last_4_weeks) as is_last_4_weeks
	,max(wdp.is_last_13_weeks) as is_last_13_weeks
from igdetails
join wdp
on igdetails.wm_start_date <=wdp.wm_date
and igdetails.wm_end_date >=wdp.wm_date
group by item_id, group_name
)
,pg as  --promo groups
( -- makes item id unique
--if there are multiple promos for an item happening, puts them all into an array called 'promo_groups'
select 
	item_id
	,json_agg(group_name ||': '||wm_start_date ||'-'||wm_end_date) as promo_groups
from promo
group by item_id
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
,eif as 
(
select
	model
	,sum(
		case
			when retailer_name = 'Walmart.com'
			then feed_quantity
			else 0
			end
		) as feed_quantity_1p
	,sum(
		case
			when retailer_name = 'Walmart DHF Direct'
			then feed_quantity
			else 0
			end
		) as feed_quantity_3p
from inventory.sf_ecomm_inventory_feeds
where 1=1
group by model
)
,find_aws as --finds the aws for l4, l13, and the 3p units
(-- finding the average weekly sales for units for the item
select 
	tool_id
	,da.model
	,retail_type_assignment
	,cat
	,sub_cat
	,group_id
	,division
	,product_name
	,account_manager
	,l4_units
	,l13_units
	,l4_units_3p
	,l13_units_3p
	,l4_units::numeric/4  as l4_units_aws
	,l13_units::numeric/13 as l13_units_aws
	,l4_units_3p::numeric/4 as l4_units_3p_aws
	,l13_units_3p::numeric/13 as l13_units_3p_aws
	,pg.promo_groups
	,iinv.quantity_on_hand
	,iinv.open_order_quantity
	,iinv.po_quantity
	,eif.feed_quantity_1p
	,eif.feed_quantity_3p
from details_agg da
left join pg
on da.tool_id::bigint = pg.item_id
left join iinv
on da.model = iinv.model
left join eif
on da.model = eif.model
where l13_units !=0 -- not including anythign that hasn't had sales for the last 13 weeks 
or l13_units_3p !=0
)
select 
*
,(l4_units_aws  - l13_units_aws)/nullif(l13_units_aws,0) as l4_over_l13
,(l4_units_3p_aws - l13_units_3p_aws)/nullif(l13_units_3p_aws,0) as l4_over_l13_3p
from find_aws
order by cat, l4_over_l13 desc
)
;
