create or replace view power_bi.product_name_pbix as 
(
with s1 as
( --find models with their upc and product name
select
	model
	,upc
	,product_name
	,date_shipped as date_compare 
from ships_schema.ships
)
,s2 as 
(
select --find max date for a model
	model
	,max(date_compare) as date_compare
from s1
group by model
)
,s3 as
( -- join max date model to list
select distinct
	s1.model
	,s1.upc
	,s1.product_name
	,s1.date_compare 
from s1
join s2
on s1.date_compare = s2.date_compare and s1.model = s2.model
)
,s4 as 
( -- rank the rows for any duplicates. ex. model 2006007 has 2 different upcs. 
	--sorting by the upc without a 0 in front of it by making it desc

select 
	model
	,upc
	,product_name
	,date_compare
	,row_number() over (partition by model order by model, upc desc) as row_ranking
	,row_number() over (ORDER BY product_name,upc, model) as product_name_id
from s3
)
select
	upc::text
	,model::text
	,product_name::text
	,product_name_id
from s4
where row_ranking = 1 -- set row rankign to 1 to get rid of any duplicates. 
)
;