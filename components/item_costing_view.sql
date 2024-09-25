create or replace view components.item_costing_view as 
( -- pull in the model and their costs
select
	model
	,product_name
	,material_cost
	,duty_cost
	,freight_cost
	,overhead_cost
	,material_cost --material + duty + freight
		+duty_cost
		+freight_cost
	as contribution_profit_cost
	,material_cost
		+duty_cost
		+freight_cost
		+overhead_cost
	as contribution_profit_cost_overhead
from components.item_costing
)
