--view used to upsert the dapl_raw into the pos_reporting dsv orders (staging to production)
--query find's the latest version of dsv orders from the API fetch run, then will use 'inserted_at' to determine the most recent occurance
--query used in queries.py -> run_orders.py
create or replace view dapl_raw.dsv_order_insert_view as 
(
with dsvr as -- raw data from dsv orders
( --pull in the dsv orders from the raw data
select
    cast(po_id ||line_number as bigint) as dsv_order_id -- concatination of the po_id & line number to make row unique
    ,po_id -- purchase order id
    ,so_id  -- store order id
    ,order_date -- date of order
    ,line_number -- customer orders many things at once. each item is broken out into a 'line'
    ,sku -- model
    ,qty -- # of items
    ,status -- order status of the item (delivered, shipped, etc.)
    ,est_ship_date -- date estimated order will arrive
    ,est_delivery_date -- estimated delivery
    ,ship_type -- type of shipping
    ,ship_address -- address of person getting items, should parse out 
    ,order_total -- will rename to order amount
    ,node --node type, 'self fufilled'
    -- ,payload
    ,customer_email --ahs string of customer email. keeping column to find unique customer accounts
    ,inserted_at -- date the data is inserted
    ,city_name
    ,state_name
    ,postal_code
    ,country
    ,address_type
    ,tracking_number
    ,now() as updated_on
    ,tracking_url
from dapl_raw.dsv_orders_3p

)
,dsvm as --dsv max
( -- find the most recenet entry for the dsv order table
select
    dsv_order_id
    ,max(inserted_at) as date_compare -- find the most recent datetime for pipeline upload
from dsvr
group by dsv_order_id
)
,dsvrm as  -- dsv raw max join
( -- find the most recent record of the dsv order data
select
    dsvr.dsv_order_id
    ,po_id
    ,so_id 
    ,order_date
    ,line_number
    ,sku
    ,qty
    ,status
    ,est_ship_date
    ,est_delivery_date
    ,ship_type
    ,ship_address
    ,order_total
    ,node 
    ,customer_email
    ,inserted_at
    ,city_name
    ,state_name
    ,postal_code
    ,country
    ,address_type
    ,updated_on
    ,tracking_number
    ,tracking_url
from dsvr
join dsvm
on dsvr.dsv_order_id = dsvm.dsv_order_id
and dsvr.inserted_at = dsvm.date_compare
)
select *
from dsvrm
)
;