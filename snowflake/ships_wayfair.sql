create or replace view walmart.core.ships_wayfair as 
(
with dimi1 as 
(
select item_sk
    ,retailer_sku
    ,retailer_model_number
    ,row_number() over ( partition by item_sk order by live_on_site_date desc )  as item_seq
from dorel_dwh.edw.xref_item_retailer
where 1=1
and retailer_item_url like '%wayfair%'
)
,di as 
(
select
    item_sk
    ,retailer_sku as item_id
from dimi1
where item_seq =1
)
,cl as 
(
select customer_sk
    ,customer_name
    ,retailer_name
    ,sales_type
from dorel_dwh.edw.dim_customer
where retailer_name like '%Wayfair%'
)
,ni as  -- new item
(
select item_sk
    ,right(model_number , len(model_number) -1) as new_model_number
from dorel_dwh.edw.dim_item
where model_number like '0%'
and item_name is null
)
,dim_i as  --dim item. used to assign item attributes
(
select
    t1.item_sk
    ,item_name
    ,model_number
    ,category_name
    ,department_name
from dorel_dwh.edw.dim_item t1
left join ni
on t1.model_number = ni.new_model_number
)
select 
fps.fact_sk
,dim_i.model_number as model
,dim_i.item_name as product_name
,item_id as tool_id
,ship_date as date_shipped
,case
    when cl.customer_sk = '8d0eadf72c6ac3576d8abc9a2ff0b6ad'
    then 'Walmart Omni'
    else cl.retailer_name
    end as retailer
,case
    when cl.customer_sk = '8d0eadf72c6ac3576d8abc9a2ff0b6ad'
    then 'Brick & Mortar'
    else cl.sales_type
    end as sale_type
 ,case
    when division_sk in ('b7f6d7c18c38393157c11a1bcd069ff7','e738b7c8145f02289abfc6a4fc2b2cb5')
    then 'Ameriwood'
    when division_sk = '264c494d79b23d86255553fea274f4b6'
    then 'Cosco Products'
    when division_sk ='4911239f226f8e2c0bbb812bbea2ce2e'
    then 'Dorel Home Products'
    when division_sk = 'f87950cd3fc0f4ae4821f5790ca90b00'
    then 'Notio'
    end as division
    ,dim_i.category_name as category
    ,dim_i.department_name as department
,shipped_quantity as units
,shipped_revenue as sales
,warehouse_code as warehouse
from dorel_dwh.edw.fact_product_sales fps
left join di
on fps.item_sk = di.item_sk
left join cl 
on fps.customer_sk = cl.customer_sk 
left join  dim_i
on fps.item_sk = dim_i.item_sk
where 1=1
and ship_date >=current_date - interval '30 days'
and cl.customer_sk in (select customer_sk from cl)
and case -- ommiting notio items that are negative
    when order_number  like '67%' and shipped_quantity <0
    then 1
    else 0 
    end !=1
)
;
