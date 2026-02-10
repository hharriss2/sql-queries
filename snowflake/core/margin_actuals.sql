
create or replace view walmart.core.margin_actuals as 
(
with ma as  -- margin actuals
( --main sale data for the margin table 
select
    date as sale_date
    ,division
    ,"model" as model_name
    ,product_name_detailed
    ,customer_key as customer_number
    ,customer_name
    ,warehouse as warehouse_number
    ,value_class
    ,units_sold
    ,gross_sales
    ,deductions
    ,net_sales
    ,standard_cost
    ,overhead_cost
    ,material_cost
    ,duty_cost
    ,std_margin
    ,variable_product_cost
    ,contribution_magrgin
    ,labor_cost
    ,returns_defective
    --dedution rate
    --average price
    --cost / item
    --standard margin
    /*get these fields*/
    --is discontinued? (calculate with the status)
from dorel_qlik_migration.reporting.margin_actuals
)
,cus as --customer info
( -- customer, sale types, and retailer info
select
    customer_nk as customer_number
    ,customer_name
    ,sales_type
    ,retailer_name
    ,retailer_type
    ,retailer_group
from dorel_dwh.edw.dim_customer
)
,di as --dim item
( -- info regarding model numbers
select
    model_number as model_name
    ,department_name
    ,category_name
    ,subcategory_name
    ,division_name
    ,item_status
    ,brand
    ,collection as collection_name
from dorel_dwh.edw.dim_item
where model_number not in ('9999999','9998')
)
select 
    sale_date
    ,division
    ,ma.model_name
    ,ma.product_name_detailed
    --customer info
    ,ma.customer_number
    ,cus.customer_name
    ,cus.sales_type
    ,cus.retailer_name
    ,cus.retailer_type
    ,cus.retailer_group
    --item info
    ,di.department_name
    ,di.category_name
    ,di.subcategory_name
    ,di.division_name
    ,di.item_status
    ,di.brand
    ,di.collection_name
    --kpi numbers
    ,ma.warehouse_number
    ,ma.value_class
    ,ma.units_sold
    ,ma.gross_sales
    ,ma.deductions
    ,ma.net_sales
    ,ma.standard_cost
    ,ma.overhead_cost
    ,ma.material_cost
    ,ma.duty_cost
    ,ma.std_margin
    ,ma.variable_product_cost
    ,ma.contribution_magrgin
    ,ma.labor_cost
    ,ma.returns_defective
from ma
left join cus
on ma.customer_number = cus.customer_number
left join di
on ma.model_name = di.model_name
)
;
