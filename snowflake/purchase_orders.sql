--used to import the purchase orders into snowflake

create or replace view WALMART.COMPONENTS.PURCHASE_ORDERS as (
select
    order_sk
    ,dc.customer_name
    ,dc.sale_type
    ,dw.warehouse_name
    ,dw.warehouse_number
    ,case
        when company_sk = 'c4ca4238a0b923820dcc509a6f75849b'
        then 0
        when company_sk = 'c81e728d9d4c2f636f067f89cc14862c'
        then 1
        end as is_crossborder
    ,di.model_number as model
    ,di.item_name as product_name
    ,order_line_number
    ,cancel_by_date
    ,shipped_date
    ,order_count_key
    ,order_line_quantity
    ,order_line_bundle_quantity
    ,order_line_price
    ,order_line_amt
    ,order_line_status
    ,order_line_performance
    ,order_priority
    ,truck_id
    ,truck_created_datetime
    ,truck_left_the_yard_date
    ,truck_left_the_yard_time
    ,pick_group
    ,building_assigned
from dorel_dwh.edw.fact_order_line fol
left join walmart.components.dim_warehouse dw
on fol.warehouse_sk = dw.warehouse_sk
left join dorel_dwh.edw.dim_item di
on fol.item_sk = di.item_sk
left join walmart.components.dim_customer dc
on fol.customer_sk = dc.customer_sk
where 1=1
and  dc.retailer_name in ('Walmart.com','Walmart Stores')
and (
    order_line_status not in 
    (
    'Shipped Via Non-PPS'
    ,'Shipped'
    )
    or shipped_date >=current_date() - interval '3 months'
)
)
;
