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
	,ic.contribution_profit_cost * qty as net_cost
	-- ,ic.contribution_profit_cost_overhead * qty as cogs_overhead
	,order_total + (commission_amt) - (rate_amount) as cogs
    ,wcv.wmcal_id
    ,inv.avail_to_sell_qty -- current inventory level
    ,mrs.price_retail
    ,mrs.num_of_variants
    ,dis3.status_id as item_status_id
from pos_reporting.dsv_orders_3p_recon dr 
left join components.item_costing_view ic
on dr.model = ic.model
left join power_bi.wm_calendar_view wcv
on dr.order_date = wcv.date
left join components.dsv_3p_inventory_agg inv
on dr.model = inv.model
left join scrape_data.most_recent_scrape mrs
on dr.item_id = mrs.item_id
left join lookups.item_status_3p is3
on is3.item_id = dr.item_id
left join power_bi.dim_item_status_3p dis3
on is3.status_name = dis3.status_name
where 1=1
and status !='Refund' -- including refunds will throw off %'s
)
,details as 
(
select 
	model
	,item_id
	,product_name
	,qty
	,order_total
	,commission_amt
	,rate_amount
    ,is_suppression_model
	,cogs
    ,net_cost
--	,cogs_overhead
	,cogs - net_cost as contribution_profit
    ,wmcal_id
    ,avail_to_sell_qty
    ,order_date
    ,price_retail
    ,num_of_variants
    ,item_status_id
from rc
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
--	,cogs_overhead
	,net_cost
	,contribution_profit
    ,case
	when contribution_profit <0 and cogs < 0 -- neg cp and cogs will show neg %
	then cast((contribution_profit / cogs) * -1 as numeric(10,2))
	else cast(contribution_profit / cogs as numeric(10,2))
	end as cp_perc
    ,cast(contribution_profit/ qty  as numeric(10,2)) as avg_contribution_profit 
	-- ,cast(contribution_profit / cogs_overhead as numeric(10,2)) as cp_overhead_perc

    ,is_suppression_model
    ,wmcal_id
    ,avail_to_sell_qty
    ,case
    	when order_date >= current_date - interval '60 days'
    	then 1
    	else 0
    	end as is_last_60_days
	,case
		when order_date >= current_date - interval '8 weeks'
		then 1
		else 0 
		end as is_last_8_weeks
    ,price_retail
    ,num_of_variants
    ,item_status_id
from details
)
;
