--query for google sheet that lets sales team help find the category by model
with s as  -- ships
( -- main shipment data. where we find cateogories needing assignment
select distinct s.model
	,s.product_name
	,cbm.cat
	,cbm.sub_cat
	,case -- boolean. 1 = needs category, 0 = doesn't need category
		when cat is null
		then 1 else 0
		end as find_cat
	,split_part(product_name,',',1) as similar_name
from ships_schema.ships s 
left join cat_by_model cbm
on s.model = cbm.model
)
,sn as --similar name
( -- find the unique model & similar name to the category
select distinct 
	model
	,similar_name
	,cat
	,sub_cat
from s 

)
,details as 
( -- join the similar names on other models with similar names to find the correct category
select distinct 
	s.model
	,s.product_name
	,sn.cat as similar_category
	,sn.sub_cat as reccomended_cat
	,ac.account_manager
from s
left join sn
on s.similar_name = sn.similar_name
left join account_manager_cat ac
on sn.cat = ac.category_name
where s.find_cat = 1
) -- details that can be loaded into the google sheet
select model as "Model"
	,product_name as "Product Name"
	,max(similar_category) as "Reccomended Cat"
	,max(reccomended_cat) as "Reccomended Cat"
	,max(account_manager) as "Reccomended Account"
from details
group by model, product_name

;

