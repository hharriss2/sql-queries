--similar to the other ships queries (ships, ships_amazon, ships_wayfair)
--this one is for querying on snowflake side, others were used to update into postgresql.
--this query will union with the ships_jde query for power BI
create or replace view walmart.core.ships_dhf as 
(
with dim_i as --dim item. basic item info
(
select
    item_sk
    ,item_name
    ,model_number
    ,category_name
    ,department_name
    ,brand
from dorel_dwh.edw.dim_item
)
,cl as 
( -- customer info such as retailer 
select customer_sk
    ,customer_name
    ,coalesce(retailer_name, customer_name) as retailer_name
    ,sales_type
    ,customer_nk
from dorel_dwh.edw.dim_customer
)
,details as 
( -- small tweaks to the shipment data to make it more relatable
select 
fps.fact_sk
,case -- removing leading 0's from models that have them
    when dim_i.item_sk is null
    then trim(fps.internal_model_number,'0000')
    else dim_i.model_number end as model
,dim_i.item_name as product_name
,ship_date as date_shipped
,cl.retailer_name as retailer
,cl.sales_type as sale_type
 ,case -- I don't have a division sk table to manually updating these
    when division_sk in ('b7f6d7c18c38393157c11a1bcd069ff7','e738b7c8145f02289abfc6a4fc2b2cb5','470152be04c675460087661ddc61ef5a')
    then 'Ameriwood'
    when division_sk = '264c494d79b23d86255553fea274f4b6'
    then 'Cosco Products'
    when division_sk ='4911239f226f8e2c0bbb812bbea2ce2e'
    then 'Dorel Home Products'
    when division_sk = 'f87950cd3fc0f4ae4821f5790ca90b00'
    then 'Notio'
    when division_sk in ('5580303dd4355ffd69693f21464cb16c','4d31937ca13433c16283f7e564f0b028')
    then 'Dorel Home Products'
    when division_sk = '46c76b5afbd6969697c36d7a0d396d9e'
    then 'Rugs America'
    when division_sk = 'ffbca00a190859d66ea08c322e3573a8'
    then 'DH Europe'
    else division_sk
    end as division
,dim_i.category_name as category
,dim_i.department_name as department
,shipped_quantity as units
,shipped_revenue as sales
,warehouse_code as warehouse_code
,dw.alternate_wh_number
,mrl.hf_customer_number
,brand
from dorel_dwh.edw.fact_product_sales fps -- main shipments table
left join cl  -- customer lookup
on fps.customer_sk = cl.customer_sk 
left join  dim_i -- item lookup
on fps.item_sk = dim_i.item_sk
left join walmart.components.monday_retailer_list mrl
on cl.customer_nk = mrl.hf_customer_number
left join walmart.dim_sources.dim_warehouses dw
on fps.warehouse_code = dw.warehouse_number
where 1=1
and ship_date >='2022-01-01'
and case -- ommiting notio items that are negative
    when order_number  like '67%' and shipped_quantity <0
    then 1
    else 0 
    end !=1
and fps.warehouse_sk != '2fa2669a02d9b4c77ed7c851c8cb301f'
--^ finance team does not recognize these sales o
)


select min(fact_sk) as fact_sk
,model
,product_name
,date_shipped
,retailer
,sale_type
,division
,category
,department
,sum(units) as units
,sum(sales) as sales
,warehouse_code
,alternate_wh_number
,hf_customer_number
,brand
from details
group by all
)