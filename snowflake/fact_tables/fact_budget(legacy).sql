--holding onto for a sec. 
create or replace view walmart.power_bi.fact_budget_dhf as 
(
with details as 
(
select
    budget_id
    ,budget_date
    ,b.sourcing_type
    ,cbm.cbm_id
    ,b.model_number
    ,pn.product_name_id
    ,dcal.cal_id as budget_cal_id
    ,dd.division_id
    ,dw.warehouse_id
    ,mrl.hf_customer_number
    ,budget_units
    ,budget_sales
    ,b.budget_deductions as deduction_sales
    ,b.variable_cost_pu
    --total costss
    ,b.material_cost_pu * budget_units as material_cost
    ,b.duty_cost_pu * budget_units as duty_cost
    ,b.freight_cost_pu * budget_units as freight_cost
    ,b.labor_cost_pu * budget_units as labor_cost
    ,b.variable_cost_pu * budget_units as variable_cost
    ,b.overhead_cost_pu * budget_units as overhead_cost
    --net sales, royalties, gross margin
    ,b.budget_sales + b.budget_deductions as net_sales
    ,b.royalties_total as royalties_sales
    ,net_sales - variable_cost - royalties_sales as gross_margin_ex_overheads
    ,gross_margin_ex_overheads/ nullif(net_sales,0) as gross_margin_ex_overheads_percent
    --std cost & margin
    ,variable_cost + overhead_cost as standard_cost
    ,standard_cost/nullif(budget_units,0) as standard_cost_per_unit
    ,net_sales - standard_cost as standard_margin
    ,standard_margin / nullif(net_sales,0) as standard_margin_percent
from walmart.components.dhf_budget b
left join walmart.dim_sources.dim_cat_by_model cbm -- dim cat by model
on b.model_number = cbm.model
left join walmart.dim_sources.dim_product_name pn -- dim product name
on cbm.product_name = pn.product_name
left join walmart.dim_sources.dim_calendar dcal -- dim calendar
on b.budget_date = dcal.cal_date
left join walmart.dim_sources.dim_division dd -- dim division
on cbm.division_name = dd.division_name
left join walmart.dim_sources.dim_warehouses dw --dim warehouse
on b.warehouse_number = dw.warehouse_number
left join walmart.components.monday_retailer_list mrl
on b.customer_number = mrl.hf_customer_number
)
select *
from details
)
;
