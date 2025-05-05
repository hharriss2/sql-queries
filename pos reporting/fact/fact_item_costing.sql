
--table to represent the cost of items
create or replace view power_bi.fact_item_costing as 
(
with ic1 as --item cost
( -- pull in the model and their costs. first, get the latest cost date for the item
select
	*
	,max(cost_date) over (partition by model) as latest_cost_date
from item_costing.item_costing_view

)
,ic as 
(
select * 
from ic1
where cost_date = latest_cost_date
)
,isc as --item shipping cost
( -- pull in estimated shipping costs 
select * 
from components.item_shipping_cost_tbl
)
,sl as --suppression list
(
select * 
from lookups.model_suppression_list
)
,mpl as --marketplace lookup
(
select model
from clean_data.current_wm_catalog_3p
where item_status = 'PUBLISHED'
)

,dc as 
(select distinct model, max(internal_item_name) as product_name
from components.dorel_catalog
group by model
)
,details as --one more clause bc postgres doesnt let me call alias names without it 
( -- joins to pull in item ids, do some math for break even point
select
	isc.model
	,coalesce(msl.product_name,mcl.product_name,dc.product_name) as product_name
	,coalesce(msl.item_id,mcl.item_id) as item_id
	,case
		when ic.model is null
		then 0
		else 1
		end as has_costing
	,isc.length
	,isc.width
	,isc.height
	,isc.weight::numeric
	,isc.zone_number
	,material_cost
	,duty_cost
	,freight_cost
	,overhead_cost
	,isc.shipping_cost::numeric as total_shipping_cost
	,contribution_profit_cost as net_cost
	-- ,contribution_profit_cost_overhead
	,cast((shipping_cost + contribution_profit_cost) /.85 as numeric(10,2)) as break_even
	-- ,cast((total_shipping_cost + contribution_profit_cost_overhead) /.85 as numeric(10,2)) as contribution_break_even_overhead
	,cast(((contribution_profit_cost * 1.2) + shipping_cost) / .85 as numeric(10,2)) as msrp
	,case
		when sl.model is not null
		then 1
		else 0
		end as is_suppression_model
	,isc.is_multi_box
	,case
		when mpl.model is not null 
		then 1
		else 0
		end as is_3p_model
	,dm.model_id
from isc
left join ic
on ic.model = isc.model
left join clean_data.master_ships_list msl
on isc.model = msl.model
left join clean_data.master_com_list mcl
on isc.model = mcl.model and msl.item_id is null
left join sl
on isc.model = sl.model
left join mpl
on isc.model = mpl.model
left join dc
on ic.model = dc.model
left join dim_sources.dim_models dm 
on isc.model = dm.model_name
)
--final results. last calc to find estimated commission ( 15% of break even )
select 
    model
	,product_name
	,item_id
	,length
	,width
	,height
	,weight
	,zone_number
	,material_cost
	,duty_cost
	,freight_cost
	,overhead_cost
	,total_shipping_cost
	,avg(total_shipping_cost) over (partition by model) as avg_shipping_cost
	,net_cost
	-- ,contribution_profit_cost_overhead
	,break_even *.15::numeric(10,2) as est_commission 
	-- ,contribution_break_even_overhead *.15::numeric(10,2) as est_commission_plus_overhead
	,break_even
    -- ,contribution_break_even_overhead
    ,has_costing
	,msrp
	,is_suppression_model
    ,is_multi_box
	,is_3p_model
	,model_id
from details
)
;

