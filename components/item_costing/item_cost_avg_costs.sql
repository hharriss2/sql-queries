--finds the average cost of items
--items have different warehouses
    --take the smallest material and duty, average the freight
    --then, sum up multi boxed items
with t1 as 
(
select 
	case
	when model like '%-1' or model like '%-2'
	then left(
			model
			,length(model) -2
			)
	else model
	end as model_group -- create a grouping for multi box items
	,model
	,description
	,material_cost -- aka factory cost
	,duty_cost -- aka terrif cost
	,freight_cost
from components.internal_item_costing
)
,t2 as 
( -- find smallest material and duty cost, average freight cost
select distinct
	model_group
	,model
	,min(description) over (partition by model_group) as description -- turn all fo the item names the same
	,min(material_cost) over(partition by model) as material_cost -- smallest for the model, not model grouping
	,min(duty_cost) over(partition by model) as duty_cost
	,avg(freight_cost) over (partition by model)::numeric(10,2) as freight_cost
from t1
)
,t3 as 
( -- sum up the costs. if non multi box, should be the same as t2 
select
	model_group as model -- model number for all boxes
	,description
	,count(model_group) as total_boxes
	,sum(material_cost) as material_cost
	,sum(duty_cost) as duty_cost
	,sum(freight_cost) as freight_cost
from t2
group by model_group,description
)
select * 
from t3