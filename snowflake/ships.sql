--view used to insert the shipment data into postgres db
create or replace view walmart.core.ships as 
(
with di1 as --dorel items 1
(-- making unique items out of the dorel items
select 
    item_sk
    ,model_number
    ,retailer_id
    ,case -- retailer id 2 is .com. trying to assign an item id to the model
    when retailer_id = 2 and item_id is not null
    then 1
    when retailer_id !=2 and item_id is not null and length(item_id) >=8 and length(item_id) <=11
    then 2
    else null
    end as priority_seq
    ,row_number() over (partition by item_sk order by priority_seq,item_id) as item_id_seq
    ,coalesce(internal_item_name, retailer_item_name) as item_name
    ,division_name
    ,item_id
from walmart.components.dorel_catalog
where 1=1
-- and item_sk = '0008c3f1eebaf964a15b9e366df9a224'
-- and item_sk = '9fa2a6b69572c88d7b79342d50325389'
)
,di as --dorel items
(
select 
    item_sk
    ,model_number
    ,item_name
    ,division_name
    ,item_id
from di1
where item_id_seq = 1
)
,cl as --customer lookup
(
select customer_sk
    ,retailer_name
    ,sales_type
from dorel_dwh.edw.dim_customer
where retailer_name || '-' ||sales_type in 
    (
    select retailer_name || '-' ||sales_type
    from dorel_dwh.edw.dim_customer
    where customer_sk in('72adfb0ea28d46e327775a8ce57912ed'
    ,'2053ba7d1adfdb168b3f555c7dc98576'
    ,'d79cf961674b3e67b65735906f66f7dd'
    ,'42887ca79b6bb0f614aefc0a56c6626d'
    ,'43e35cc5fb59d8cb76180d38223fdcf1'
    ,'23ac9bb96d8d9461a5693e2db6799afd'
    ,'ac0355c7bc9deb92a1d9acd1d2298698'
    ,'2abd3ab3ef00df78a8adccfe2ea14da0'
    ,'84e2a8a5006e4d7d96161eff02f28181'
    ,'1ea064b297c4f5e23de6f6a1a2b825df')
    )
or customer_sk = '8d0eadf72c6ac3576d8abc9a2ff0b6ad'
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
,coalesce(di.model_number,dim_i.model_number) as model
,coalesce(di.item_name,dim_i.item_name) as product_name
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