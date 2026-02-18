--power bi report for the budget and item costing 
    --fact table also connects with the facts_ships_dhf table. 
create or replace view walmart.power_bi.fact_budget_dhf as 
(
with b_month as -- budget by month
( -- making joins on the budget table before multiplying all the rows by 30.
select
    budget_date
    ,b.sourcing_type
    ,cbm.cbm_id
    ,b.model_number
    ,pn.product_name_id
    -- ,dcal.cal_id as budget_cal_id
    ,dd.division_id
    ,dw.warehouse_id
    ,mrl.hf_customer_number
    ,budget_units as budget_units_month -- divide by days
    ,budget_sales as budget_sales_month -- divide bt dats
    --^ alias and going back to original name once divided by day s
    ,b.budget_deductions -- divide by days
    ,b.variable_cost_pu
    ,b.material_cost_pu
    ,b.duty_cost_pu
    ,b.freight_cost_pu
    ,b.labor_cost_pu
    ,b.overhead_cost_pu
    ,b.royalties_total -- divide by days
from walmart.components.dhf_budget b
left join walmart.dim_sources.dim_cat_by_model cbm -- dim cat by model
on b.model_number = cbm.model
left join walmart.dim_sources.dim_product_name pn -- dim product name
on cbm.product_name = pn.product_name
left join walmart.dim_sources.dim_division dd -- dim division
on cbm.division_name = dd.division_name
left join walmart.dim_sources.dim_warehouses dw --dim warehouse
on b.warehouse_number = dw.warehouse_number
left join walmart.components.monday_retailer_list mrl
on b.customer_number = mrl.hf_customer_number
)
select
    dcal.cal_date as budget_date
    ,dcal.cal_id
    ,sourcing_type
    ,cbm_id
    ,model_number
    ,product_name_id
    ,dcal.cal_id as budget_cal_id
    ,division_id
    ,warehouse_id
    ,hf_customer_number
    ,budget_units_month / dcal.total_days_in_month as budget_units -- divide by days
    ,budget_sales_month / dcal.total_days_in_month as budget_sales  -- divide bt dats
    --^ alias and going back to original name once divided by day s
    ,budget_deductions / dcal.total_days_in_month as deduction_sales -- divide by days
    ,variable_cost_pu
    --total costs
    ,material_cost_pu * budget_units as material_cost
    ,duty_cost_pu * budget_units as duty_cost
    ,freight_cost_pu * budget_units as freight_cost
    ,labor_cost_pu * budget_units as labor_cost
    ,variable_cost_pu * budget_units as variable_cost
    ,overhead_cost_pu * budget_units as overhead_cost
    --net sales, royalties, gross margin
    ,budget_sales + deduction_sales as net_sales
    ,royalties_total / dcal.total_days_in_month as royalties_sales -- divide by days
    ,net_sales - variable_cost - royalties_sales as gross_margin_ex_overheads
    ,gross_margin_ex_overheads/ nullif(net_sales,0) as gross_margin_ex_overheads_percent
    --std cost & margin
    ,variable_cost + overhead_cost as standard_cost
    ,standard_cost/nullif(budget_units,0) as standard_cost_per_unit
    ,net_sales - standard_cost as standard_margin
    ,standard_margin / nullif(net_sales,0) as standard_margin_percent
from b_month
left join walmart.dim_sources.dim_calendar dcal
on b_month.budget_date = date_trunc('month',dcal.cal_date)
where 1=1


)
;