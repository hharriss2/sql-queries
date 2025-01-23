--find the average cost of an item
create or replace view item_costing.avg_item_cost as 
(
select model
	,max(description) as product_name
	,avg(material_cost) as material_cost
	,avg(duty_cost) as duty_cost
	,avg(freight_cost) as freight_cost
	,avg(total_overhead_cost) as total_overhead_cost
from item_costing.current_item_costing_view
where warehouse_number != '5' -- remove warehouse 5
group by model
)
;
-- insert into the item costing table that takes averages.
insert into components.item_costing(model, material_cost,duty_cost,freight_cost,overhead_cost,product_name)
select model, material_cost,duty_cost,freight_cost,total_overhead_cost,product_name
from item_costing.avg_item_cost
on conflict(model)
do update set
material_cost = excluded.material_cost
,duty_cost = excluded.duty_cost
,freight_cost = excluded.freight_cost
,overhead_cost = excluded.overhead_cost
,product_name = excluded.product_name
;