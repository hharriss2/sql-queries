--view finds a model for every item id listed with retail sales.
--parabola uses this view to insert into clean_data.com_product_list
create or replace view clean_data.retail_com_model_tool_insert as 
(
with rsmax as 
(
select tool_id
	,max(sale_date) as latest_sale_date
from pos_reporting.retail_sales
group by tool_id
)
,rs1 as ( --retail sales 1
    --first step in finding a unique tool id and product name combo
select distinct 
    tool_id
    ,product_name
    ,sale_date
from pos_reporting.retail_sales 
)
,rs as -- retail sales (final) 
( -- finds the tool id and the most recent product name for the sale 
select rsmax.tool_id::bigint as item_id
	,rs1.product_name
from rs1
join rsmax
on rsmax.tool_id = rs1.tool_id
and  rsmax.latest_sale_date = rs1.sale_date
)
,its as  --item scrape (retail scrape)
( -- list of the item id and model info from the scrape data
select * 
from scrape_data.latest_item_scrape
where item_id in  -- only trying to match .com retail sale items
	(select distinct tool_id::bigint
	from pos_reporting.retail_sales
	)
and model_name !=''
and model_name is not null
)
,sm as --ship model
( -- model,item id, and division relationship
select * 
from clean_data.ships_model_tool_insert
)
,wc as --walmart catalog
(
select distinct
	item_id::bigint as item_id
	,ltrim(upc,'0')::bigint as upc_key
from wm_catalog2
where 1=1
and  item_id ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' -- removing any item id's that aren't # only
and item_id::bigint not in (select item_id from its) -- don't want to look at items already existing in the scrape data. reduces the data set
and upc ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$' 

)
,wcm as --walmart catalog model
( -- joins together the wm catalog and ships  model on upc
select 
wc.item_id
,sm.model
,sm.division
from wc
left join sm
on wc.upc_key = sm.upc_key
)
select 
	rs.item_id
--	,its.model_name as retail_scrape_model
--	,sm.model as ships_model
--	,wcm.model as  walmart_cat_model
	,coalesce(sm.model,wcm.model,its.model_name) as model_name -- prioritized shipment (our model), wm catalogs, then scrape datas model (possibly a white lable) 
	,coalesce(sm.division,wcm.division) as division_name
	,coalesce(its.product_name,rs.product_name) as product_name
    ,case
        when its.product_name is null
        then 0
        else 1 
        end as is_scrape_product_name
from rs
left join its
on rs.item_id =its.item_id
left join sm
on rs.item_id = sm.item_id
left join wcm
on wcm.item_id = rs.item_id
)
;
