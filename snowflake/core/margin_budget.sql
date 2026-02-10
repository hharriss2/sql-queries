create or replace view wlmart.core.margin_budget as 

(
with mb as  -- margin budget
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
from dorel_qlik_migration.reporting.margin_budget
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
    ,mb.model_name
    ,mb.product_name_detailed
    --customer info
    ,mb.customer_number
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
    ,mb.warehouse_number
    ,mb.value_class
    ,mb.units_sold
    ,mb.gross_sales
    ,mb.deductions
    ,mb.net_sales
    ,mb.standard_cost
    ,mb.overhead_cost
    ,mb.material_cost
    ,mb.duty_cost
    ,mb.std_margin
    ,mb.variable_product_cost
    ,mb.contribution_magrgin
    ,mb.labor_cost
    ,mb.returns_defective
from mb
left join cus
on mb.customer_number = cus.customer_number
left join di
on mb.model_name = di.model_name
);
