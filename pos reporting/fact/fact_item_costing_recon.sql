--report combines the item costing and dsv recon reports into one report for viewing
create or replace view power_bi.fact_item_costing_recon as 
(
with rc as --recon costs
(-- report impliments both recon and costs for the order
select dr.*
	,(ic.duty_cost * qty) as duty_cost
	,(ic.material_cost * qty) as material_cost
	,(ic.freight_cost * qty) as freight_cost
	,(ic.overhead_cost * qty) as overhead_cost
	,ic.contribution_profit_cost * qty as cogs
	,ic.contribution_profit_cost_overhead * qty as cogs_overhead
	,order_total + (commission_amt) - (rate_amount) as contribution_profit
from pos_reporting.dsv_orders_3p_recon dr 
left join components.item_costing_view ic
on dr.model = ic.model
where 1=1
and status !='Refund' -- including refunds will throw off %'s
)
select 
	model
	,item_id
	,product_name
	,qty
	,order_total
	,commission_amt
	,rate_amount
	,cogs
	,cogs_overhead
	,contribution_profit - cogs as  contribution_profit
	,cast(contribution_profit / cogs as numeric(10,2)) as cp_perc
	,cast(contribution_profit / cogs_overhead as numeric(10,2)) as cp_overhead_perc
from rc
)
;