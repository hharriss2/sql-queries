
--view used to populate retail_model_tool_insert view. 
	--ships_model_tool_insert ->
		--retail_model_tool_insert ->
			--com_to_master_com_insert 
create or replace view clean_data.ships_model_tool_insert as 
(
--cleaning up shipment data as much as we can 
with s as  -- shipment data
( -- find the latest model, tool, division, and upc for an item
select
	model
	,upc
	,case
		when tool_id !~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'
		then null -- if item id does not have a number in the name, then we turn it to null
        when tool_id = '0'
        then null -- if item id =0, then turn it to null
		else btrim(tool_id,'  ')::bigint  -- some item id's get entered in with a werid space. this will get rid of so we can convert to a big int data type
		end as item_id
	,division 
	,max(date_shipped) as latest_ship_date
from ships_schema.ships
where 1=1
and upc::text  ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'
--^only looks for UPC's with numbers
and retailer in ('Walmart.com', 'Walmart Stores','SamsClub.com')
--cleaning up for walmart retails only
group by 
	model
	,upc
	,item_id
	,division
)


,max_model as --find the most recent model 
( 
select model
	,upc
	,item_id
	,latest_ship_date
	,division
	,row_number() over (partition by model order by latest_ship_date desc) as model_seq -- ranking the latest to oldest combo for a model 
	,ltrim(upc,'0')::bigint as upc_key-- create upc as a bigint
	,row_number() over (partition by item_id order by latest_ship_date desc) as item_id_seq_s1
	
from s
)
select
	model
	,upc
	,item_id
	,latest_ship_date
	,division
	,model_seq
	,upc_key
	,case --used to filter to item id with most recent shipment and its model
		when item_id is null then 1 
		else item_id_seq_s1
		end as item_id_seq
from max_model
where model_seq =1 -- 1 will show the latest record for the model tool combo
);