--view to find the most recent name for a model in the ships data
--uploads into clean_data.master_ships_list
create or replace view clean_data.ships_product_name_insert as 
(
with s as
(
select * 
from ships_schema.ships
)
,spn1 as --ships product_name step 1
( -- find most recent model product name relationship
select 
	model
	,product_name
	,max(date_shipped) as date_compare
from s
group by model, product_name
)
,spn2 as --narrowing the results a little more 
(
select
	model
	,product_name
	,row_number() over (partition by model order by date_compare desc) as model_seq_id
from spn1
)
,spn as --find model product name results
(
select
	model
	,product_name
from spn2
where model_seq_id = 1
)
select * 
from spn
)