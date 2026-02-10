--inventory feeds for items for walmart
create or replace view walmart.components.ecomm_intentory_feeds as 
(
with details as 
(
select 
    foi.fact_sk
    ,dc.customer_name
    ,di.model_number as model
    ,di.item_name as product_name
    ,foi.warehouse_sk
    ,dw.warehouse_name
    ,dw.warehouse_number
    ,contract_number
    ,feed_quantity
    ,foi.retailer_name
    ,date_created
    ,date_updated
    ,dealer_item_number
    ,max(date_updated) over (partition by dc.customer_name, di.model_number, contract_number, foi.retailer_name, dc.customer_name) 
    as latest_date_updated
    --use this to find the most recent feed
from dorel_dwh.edw.fact_dropship_inventory foi
left join walmart.components.dim_customer dc
on foi.customer_sk = dc.customer_sk
left join walmart.components.dim_warehouse dw
on foi.warehouse_sk = dw.warehouse_sk
left join dorel_dwh.edw.dim_item di
on foi.item_sk  = di.item_sk
where 1=1
and foi.retailer_name in ('Walmart Stores','Walmart.com','Walmart DHF Direct') -- want these retailers only
and archive_flag =0 -- want current records
and contract_number in (94,65109) --for some reason, this is the current contract
)
select * 
from details
where date_updated = latest_date_updated
)