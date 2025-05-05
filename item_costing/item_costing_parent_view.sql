--view used if there is not an exact model match. you can join the records on the parent key instead
create or replace view item_costing.item_costing_parent_view as 
(
select parent_model
	,cost_date
	,box_type
	,is_multi_box_desc
	,max(material_cost) as material_cost
	,max(freight_cost) as freight_cost
	,max(overhead_cost) as overhead_cost
	,max(duty_cost) as duty_cost
    ,max(labor_cost) as labor_cost
	,max(contribution_profit_cost) as contribution_profit_cost
	,max(contribution_profit_cost_overhead) as contribution_profit_cost_overhead
from item_costing.item_costing_view
--where parent_model like '%4240449%'
group by parent_model
	,cost_date
	,box_type
	,is_multi_box_desc
)
;
