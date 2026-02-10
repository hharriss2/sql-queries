--view finds a model for every item id listed with retail sales.
--parabola uses this view to insert into clean_data.com_product_list
create or replace view clean_data.retail_com_model_tool_insert as 
(
with rsmax as 
(
select item_id
	,max(sale_date) as latest_sale_date
from retail_link_pos
group by item_id
)
,rs1 as ( --retail sales 1
    --first step in finding a unique tool id and product name combo
select distinct 
    item_id
    ,product_name
    ,sale_date
from retail_link_pos
)
,rs as -- retail sales (final) 
( -- finds the tool id and the most recent product name for the sale 
select rsmax.item_id as item_id
	,rs1.product_name
from rs1
join rsmax
on rsmax.item_id = rs1.item_id
and  rsmax.latest_sale_date = rs1.sale_date
)
,its as  --item scrape (retail scrape)
( -- list of the item id and model info from the scrape data
select
	item_id
	,product_name
	,manufacturer_name
	,case
		when model_name like 'MS%'
		then null
		when model_name like 'BH%'
		then null
		when model_name = 'Credenza'
		then null
		else model_name
		end as model_name
	,upc
	,base_id
from scrape_data.most_recent_scrape
where item_id in  -- only trying to match .com retail sale items
	(select distinct tool_id::bigint
	from pos_reporting.retail_sales
	)
and model_name !=''
and model_name is not null
)
,sm as --ship model
( -- model,item id, and division relationship
select distinct 
	model
	,case
		when item_id !~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'
		then null -- if item id does not have a number in the name, then we turn it to null
        when item_id = '0'
        then null -- if item id =0, then turn it to null
		else btrim(item_id,'  ')::bigint 
		 -- some item id's get entered in with a werid space. this will get rid of so we can convert to a big int data type
		end as item_id
	,division_name::varchar as division_name
	,row_number() over (partition by item_id order by dorel_catalog_id desc) as item_seq
	--used to find the latest model to item id relationship
from components.dorel_catalog
where division_name in (select division_name from components.dorel_catalog where retailer_id !=404)
and item_id not like '%E+%'

)

,mti as -- model tool insert
( -- finalized part of the query. 
	--there are some values that are still null, but accounted for on the master tool upload
	--because of this, we are joining MTI one last time to master com list, to override nulls
select distinct
	rs.item_id
--	,its.model_name as retail_scrape_model
--	,sm.model as ships_model
--	,wcm.model as  walmart_cat_model
	,coalesce(sm.model::varchar,its.model_name) as model_name -- prioritized shipment (our model), wm catalogs, then scrape datas model (possibly a white lable) 
	,sm.division_name
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
where 1=1
and sm.item_seq = 1

) -- final final part of the query
--if com product list has a value but the MTI is null, then we keep master com value 
select
	mti.item_id
	,coalesce(mti.model_name::varchar, cpl.model) as model_name
	,coalesce(mti.division_name, cpl.division) as division_name
	,case
		when mti.product_name like '%Dixie%'
		then coalesce(cpl.product_name, mti.product_name)
		else coalesce(mti.product_name, cpl.product_name)
		end  as product_name
	,coalesce(mti.is_scrape_product_name,cpl.is_scrape_product_name) as is_scrape_product_name
from mti -- used to be clean_data.com_product_list_insert_view  I think?
left join clean_data.com_product_list cpl
on mti.item_id = cpl.item_id
)
;
