--item costing by model by costing date by warehouse feeds
--finds the models in item costing sheet by warehouse and compares to  3p models that are feeding
--if it's feeding for the warehouse, then use the max amount for the item costing
create or replace view item_costing.item_costing_view as 
(
with iff as 
(-- find the unique model and warehouse number that are feeding for 3p business
select distinct 
	model
	,warehouse_number
from inventory.sf_ecomm_inventory_feeds
where retailer_name = 'Walmart DHF Direct'
)
,icw as 
(
select model
	,cost_date
	,count(distinct warehouse_number) as warehouse_count
from item_costing.item_costing_tbl_agg
--where model = '3619013COM'
group by model, cost_date
)
,icfj as --item cost feed join as 
(
select ic.*
	,case
		when if1.warehouse_number is not null
		then 'model in feed'-- exact match of the feeds
		when if2 is not null 
		then 'parent model in feed' -- parent model match on the feeds
		when ic.warehouse_number::integer in (4,41,51,66,8,82,83,84,87,93)
		then 'wh not in feed'--the warehouse number is not in the feed
		else 'no feed found'--no matched foud on the feed
		end as feed_type
		,icw.warehouse_count
--	,row_number() over (partition by parent_model, ic.warehouse_number, cost_date, box_type) as warehouse_count
	--number of warehouses accounted for in with this parent model
from item_costing.item_costing_tbl_agg ic
left join icw
on ic.model = icw.model
and ic.cost_date = icw.cost_date
left join iff if1
on ic.model = if1.model
and ic.warehouse_number = if1.warehouse_number
left join iff if2
on ic.parent_model = if2.model
and ic.warehouse_number = if2.warehouse_number
where 1=1
)
,details_agg as 
(
select distinct 
	model
	,parent_model
	,cost_date
	,box_type
	,is_multi_box_desc
	,max(material_cost) over (partition by model) as single_material_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = 1
		then material_cost
		when feed_type !='wh not in feed'
		then material_cost
		else null
		end
		) over (partition by parent_model) as material_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = 1
		then freight_cost
		when feed_type !='wh not in feed'
		then freight_cost
		else null
		end
		) over (partition by parent_model) as freight_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = 1
		then duty_cost
		when feed_type !='wh not in feed'
		then duty_cost
		else null
		end
		) over (partition by parent_model) as duty_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = 1
		then overhead_cost
		when feed_type !='wh not in feed'
		then overhead_cost
		else null
		end
		) over (partition by parent_model) as overhead_cost
from icfj
--where parent_model = '1000306COM'
order by parent_model,cost_date desc, model
)
select * 
	,material_cost --material + duty + freight
		+duty_cost
		+freight_cost
	as contribution_profit_cost
	,material_cost
		+duty_cost
		+freight_cost
		+overhead_cost
	as contribution_profit_cost_overhead
from details_agg
)
