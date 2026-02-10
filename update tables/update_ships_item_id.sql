--after uploading the ships to the dapl raw, this query will update the item id used in shipments for production
create or replace view etl_views.update_ships_item_id as 
(
with s1 as 
(
SELECT id
,model
,sale_type
	,case
		when retailer = 'Walmart Omni' and division = 'Notio'
		then 1
		when retailer = 'Walmart Stores'
		then 1
		when retailer = 'Sam''s Club' 
		then 1
		else 2 
		end as retailer_id
from ships_schema.ships
where date_shipped >='2025-09-19'

)
,mcl as 
(select model
,item_id
,t2.retailer_type_id
,t2.inserted_at
,row_number() over (partition by model, retailer_type_id order by inserted_at desc, item_id desc) as model_seq
from clean_data.master_com_list t2
where model in (select model from s1)
)
select
	s1.id 
	,s1.model
	,mcl.item_id
from s1
left join mcl
on s1.model = mcl.model
and s1.retailer_id = mcl.retailer_type_id
where 1=1
and model_seq = 1
and mcl.item_id is not null
)
;


update ships_schema.ships t1 
set tool_id = t2.item_id::text
from etl_views.update_ships_item_id t2
where t1.id = t2.id