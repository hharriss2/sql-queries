--table to represent the cost of items
create or replace view power_bi.fact_item_costing as 
(
with ic as --item cost
( -- pull in the model and their costs
select
	*
from components.item_costing_view
)
,isc as --item shipping cost
( -- pull in estimated shipping costs 
select * 
from components.item_shipping_cost
)
,details as --one more clause bc postgres doesnt let me call alias names without it 
( -- joins to pull in item ids, do some math for break even point
select
	isc.model
	,coalesce(msl.product_name,mcl.product_name,ic.product_name) as product_name
	,coalesce(msl.item_id,mcl.item_id) as item_id
	,case
		when ic.model is null
		then 0
		else 1
		end as has_costing
	,isc.length
	,isc.width
	,isc.height
	,isc.weight
	,isc.zone_number
	,isc.base_residential_rate
	,isc.additional_weight_surcharge
	,isc.oversize_surcharge
	,isc.fuel_surcharge
	,isc.additional_handle_surcharge
	,material_cost
	,duty_cost
	,freight_cost
	,overhead_cost
	,isc.total_shipping_cost
	,contribution_profit_cost
	,contribution_profit_cost_overhead
	,cast((total_shipping_cost + contribution_profit_cost) /.85 as numeric(10,2)) as contribution_break_even
	,cast((total_shipping_cost + contribution_profit_cost_overhead) /.85 as numeric(10,2)) as contribution_break_even_overhead
from isc
left join ic
on ic.model = isc.model
left join clean_data.master_ships_list msl
on ic.model = msl.model
left join clean_data.master_com_list mcl
on ic.model = mcl.model and msl.item_id is null
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
	,base_residential_rate
	,additional_weight_surcharge
	,oversize_surcharge
	,fuel_surcharge
	,additional_handle_surcharge
	,material_cost
	,duty_cost
	,freight_cost
	,overhead_cost
	,total_shipping_cost
	,avg(total_shipping_cost) over (partition by model) as avg_shipping_cost
	,contribution_profit_cost
	,contribution_profit_cost_overhead
	,contribution_break_even *.15::numeric(10,2) as est_commission 
	,contribution_break_even_overhead *.15::numeric(10,2) as est_commission_plus_overhead
	,contribution_break_even
    ,contribution_break_even_overhead
    ,has_costing
    
from details
)
;