--view inserts into the clean_data.master_ships_list table
create or replace view clean_data.master_ships_insert_view as 
(
with smt as  -- ships model tool relationship
(
select * 
	,max(item_id) over (partition by upc) as max_item_id
		--find the highest # itemed number. going to coalesce if the item_id is null
from clean_data.ships_model_tool_insert
where 1=1
)
,rs as 
(
select tool_id
	,model
	,max(sale_date) as latest_sale
from pos_reporting.wm_com_pos
group by tool_id, model
)
,details as 
(
select smt.model
	,coalesce(smt.item_id,max_item_id) as item_id
	,smt.division
	,rs.tool_id::bigint as rs_item_id
	,row_number() over (partition by smt.model order by rs.latest_sale desc) as seq_rs_tool -- assign the latest tool id used as a 1
	,rs.latest_sale
	,smt.upc
from smt
left join rs
on smt.model = rs.model
)
,wm as --walmart model
(
select distinct
	max(item_id) as item_id
	,supplier_stock_id as model
from wm_catalog
group by supplier_stock_id
)
,sl as --ships lookup
(
select * 
from lookups.lookup_ships
)
,slmax as --ships lookup max
( -- finds the max record for the most relevant lookup data
select model
	,max(inserted_at) as date_compare
from sl
group by model
)
,slf as --ships lookup final
( -- most recent record for the model
select
	sl.model
	,sl.item_id
	,sl.upc
	,sl.division
	,1 as is_lookup
from sl 
join slmax
on sl.model = slmax.model
and sl.inserted_at = slmax.date_compare
)

select 
	details.model
	,coalesce(slf.item_id,rs_item_id, details.item_id,wm.item_id::bigint) as item_id
	,coalesce(slf.upc::varchar,details.upc) as upc
	,coalesce(slf.is_lookup,0) as is_lookup
	,now() as updated_on
	,coalesce(slf.division,details.division) as division
from details
left join wm
on details.model = wm.model
left join slf
on details.model = slf.model
where seq_rs_tool =1
)
;
 