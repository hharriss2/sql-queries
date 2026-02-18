--fact table to connnect snowflake source to power bi  for the dhf shipment report
--combines historical ships with new ships & item costing
create or replace view power_bi.fact_ships_dhf as 
(
with ships_union as -- appending shipments from JDE snowflake into DHP snowflake instances
(
select
    order_id as ships_id
    ,model
    ,product_name
    ,date_shipped
    ,retailer
    ,sale_type
    ,division
    ,units::numeric(10,2) as units
    ,sales
    ,warehouse_code
    ,hf_customer_number
    ,brand
    ,warehouse_code as alternate_wh_number
from walmart.core.ships_jde
union all
select
    fact_sk as ships_id
    ,model
    ,product_name
    ,date_shipped
    ,retailer
    ,sale_type
    ,division
    ,units::numeric(10,2) as units
    ,sales
    ,warehouse_code
    ,hf_customer_number
    ,brand
    ,alternate_wh_number
from walmart.core.ships_dhf
)
select
    ships_id -- unqiue identifier for shipments. fact sk on DH side, order number + line number on JDE side
    ,su.model
    ,cbm.cbm_id -- dim for model, cat , sub cat, and department
    ,cbm.group_id_id -- dim for walmart group id's. Used for omni ships reporting
    ,product_name_id -- dim for product names
    ,date_shipped -- date value in case of front end needs
    ,dcal.cal_id -- another date value with more robust columns
    ,bcal.cal_id as budget_cal_id
    ,dretail.retailer_id -- retailer name
    ,dd.division_id  -- division name 
    ,dw.warehouse_id -- warehouse code/number/ and country of origin
    ,dst.sales_type_id
    ,hf_customer_number
    ,units
    ,sales
    --item costing
    ,(coalesce(ic.deduction_percent,0) * sales) as deduction_sales
    ,cast(ic.material_cost_pu + ic.duty_cost_pu + ic.freight_cost_pu + ic.labor_cost_pu as numeric(10,4)) as variable_cost_pu
        --^variable cost per unit
    --total costs (units * costs)
    ,ic.material_cost_pu * units as material_cost
    ,ic.duty_cost_pu * units as duty_cost
    ,ic.freight_cost_pu * units as freight_cost
    ,ic.labor_cost_pu * units as labor_cost
    ,cast(ic.material_cost_pu + ic.duty_cost_pu + ic.freight_cost_pu + ic.labor_cost_pu as numeric(10,4))
        * units as variable_cost
            --have to repeat formula for variable cost bc of the decimal places not rounding
    ,ic.overhead_cost_pu * units as overhead_cost
    --net sales, royalties, gross margin
    ,sales + deduction_sales as net_sales
    ,coalesce(net_sales * ic.royalties_percent,0) as royalties_sales
    ,net_sales - variable_cost - royalties_sales as gross_margin_ex_overheads
    ,gross_margin_ex_overheads/nullif(net_sales,0) as gross_margin_ex_overheads_percent
    --std cost & margin
    ,(variable_cost + overhead_cost)::numeric(10,2) as standard_cost
    ,standard_cost/nullif(units,0) as standard_cost_per_unit
    ,net_sales - standard_cost as standard_margin
    ,standard_margin/nullif(net_sales,0) as standard_margin_percent
from ships_union su
left join walmart.dim_sources.dim_cat_by_model cbm -- model, category, and deparmtent dim table
on su.model = cbm.model
left join walmart.dim_sources.dim_product_name dpn --product name
on su.product_name = dpn.product_name
left join walmart.dim_sources.dim_calendar dcal -- calendar
on su.date_shipped = dcal.cal_date
left join walmart.dim_sources.dim_calendar bcal --budget calendar
on date_trunc('month',su.date_shipped)::date = bcal.cal_date
left join walmart.dim_sources.dim_retailer dretail -- retailer
on su.retailer = dretail.retailer_name
left join walmart.dim_sources.dim_division dd -- division
on su.division = dd.division_name
left join walmart.dim_sources.dim_warehouses dw --dim warehouses
on su.warehouse_code = dw.warehouse_number
left join walmart.dim_sources.dim_sales_type dst -- dim sales_type
on su.sale_type = dst.sales_type
--joining item costing sheets
left join walmart.components.item_costing_2 ic --item cositng
on su.model = ic.model_number
    and date_trunc('month',su.date_shipped)::date = ic.costing_date
    and su.alternate_wh_number = ic.alternate_wh_number
    and su.hf_customer_number = ic.customer_number
    and su.model = ic.model_number
--where clauses
where 1=1
)
;