create or replace view WALMART.COMPONENTS.PURCHASE_ORDERS as (
select
    fol.order_sk
    ,po_ref_number
    ,fol.customer_sk
    ,fol.warehouse_sk
    ,case
        when company_sk = 'c4ca4238a0b923820dcc509a6f75849b'
        then 0
        when company_sk = 'c81e728d9d4c2f636f067f89cc14862c'
        then 1
        end as is_crossborder
    ,di.model_number as model
    -- ,di.item_name as product_name
    ,order_line_number
    ,cancel_by_date
    ,coalesce(shipped_date, cancel_by_date - interval '7 days') as shipped_date
    ,order_count_key
    ,order_line_quantity
    ,order_line_bundle_quantity
    ,order_line_price
    ,order_line_amt
    ,order_line_status
    ,order_line_performance
    ,order_priority
    ,fol.truck_id
    ,fol.truck_created_datetime
    ,fol.truck_left_the_yard_date
    ,fol.truck_left_the_yard_time
    ,pick_group
    ,fol.building_assigned
    ,dor.order_date
from dorel_dwh.edw.fact_order_line fol
left join walmart.components.dim_warehouse dw
on fol.warehouse_sk = dw.warehouse_sk
left join dorel_dwh.edw.dim_item di
on fol.item_sk = di.item_sk
-- left join dorel_dwh.edw.dim_customer dc
-- on fol.customer_sk = dc.customer_sk
left join dorel_dwh.edw.dim_order dor
on fol.order_sk = dor.order_sk
where 1=1
-- and  dc.retailer_name in ('Walmart.com','Walmart Stores')
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