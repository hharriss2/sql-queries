create or replace view walmart.core.margin_forecast as 

(
with mf as  -- margin budget
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
from dorel_qlik_migration.reporting.margin_forecast
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
    ,mf.model_name
    ,mf.product_name_detailed
    --customer info
    ,mf.customer_number
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
    ,mf.warehouse_number
    ,mf.value_class
    ,mf.units_sold
    ,mf.gross_sales
    ,mf.deductions
    ,mf.net_sales
    ,mf.standard_cost
    ,mf.overhead_cost
    ,mf.material_cost
    ,mf.duty_cost
    ,mf.std_margin
    ,mf.variable_product_cost
    ,mf.contribution_magrgin
    ,mf.labor_cost
    ,mf.returns_defective
from mf
left join cus
on mf.customer_number = cus.customer_number
left join di
on mf.model_name = di.model_name
);
