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
	,count(distinct case when warehouse_number::integer in (5,4,41,51,66,8,82,83,84,87,93)
	then warehouse_number else null end) as non_feed_warehouse_count
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
		when ic.warehouse_number::integer in (5,4,41,51,66,8,82,83,84,87,93)
		then 'wh not in feed'--the warehouse number is not in the feed
		else 'no feed found'--no matched foud on the feed
		end as feed_type
		,icw.warehouse_count
		,icw.non_feed_warehouse_count
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
-- and ic.warehouse_number !='5'
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
		when feed_type = 'wh not in feed' and warehouse_count = non_feed_warehouse_count
		then material_cost
		when feed_type ='no feed found' and warehouse_count = non_feed_warehouse_count
		then material_cost
		when feed_type not in('wh not in feed')
		then material_cost
		else null
		end
		) over (partition by parent_model, cost_date) as material_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = non_feed_warehouse_count
		then freight_cost
		when feed_type ='no feed found' and warehouse_count = non_feed_warehouse_count
		then freight_cost
		when feed_type not in('wh not in feed')
		then freight_cost
		else null
		end
		) over (partition by parent_model, cost_date) as freight_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = non_feed_warehouse_count
		then duty_cost
		when feed_type ='no feed found' and warehouse_count = non_feed_warehouse_count
		then duty_cost
		when feed_type not in('wh not in feed')
		then duty_cost
		else null
		end
		) over (partition by parent_model, cost_date) as duty_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = non_feed_warehouse_count
		then overhead_cost
		when feed_type ='no feed found' and warehouse_count = non_feed_warehouse_count
		then overhead_cost
		when feed_type not in('wh not in feed')
		then overhead_cost
		else null
		end
		) over (partition by parent_model, cost_date) as overhead_cost
	,max(case
		when feed_type = 'wh not in feed' and warehouse_count = non_feed_warehouse_count
		then labor_cost
		when feed_type ='no feed found' and warehouse_count = non_feed_warehouse_count
		then labor_cost
		when feed_type not in('wh not in feed')
		then labor_cost
		else null
		end
		) over (partition by parent_model, cost_date) as labor_cost
from icfj
-- where parent_model = '2402884COM'
order by parent_model,cost_date desc, model
)
select * 
	,material_cost --material + duty + freight
		+duty_cost
		+freight_cost
        +labor_cost
	as contribution_profit_cost
	,material_cost
		+duty_cost
		+freight_cost
        +labor_cost
		+overhead_cost
	as contribution_profit_cost_overhead
from details_agg
)
;

