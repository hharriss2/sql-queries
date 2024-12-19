create or replace view walmart.components.item_inventory as 
(
with ri as --recent inventory
( -- used to find the most current inventory date
select item_sk
    ,warehouse_sk
    ,max(inventory_date) recent_inventory_date
from dorel_dwh.edw.fact_product_inventory fi
where inventory_date <=current_date()
-- and item_sk = '72262b29ee1378e83174daf00643aa05'
-- and warehouse_sk = 'eeaecf978450d9c7b398bd506660fb43'
group by item_sk
    ,warehouse_sk
)
,ia as  --inventory aggregate
( --aggregates the item inventory data to give total current inventory
--this table is transactional so you can have many OH's a day
select
    di.model_number as model
    -- ,fi.fact_sk
    ,fi.item_sk
    ,dw.warehouse_sk
    ,dw.warehouse_name
    ,dw.warehouse_number
    ,fi.inventory_date
    ,sum(quantity_on_hand) as quantity_on_hand
    ,open_order_quantity
    ,on_water_quantity
    -- ,sum(open_order_quantity) as open_order_quantity
    -- ,sum(on_water_quantity) as on_water_quantity
    ,po_quantity
    ,inventory_turns
    ,di.model_number || warehouse_name as un_key --testing out this key to confirm uniqueness
from dorel_dwh.edw.fact_product_inventory fi
join ri 
on fi.item_sk = ri.item_sk
and fi.warehouse_sk = ri.warehouse_sk
and fi.inventory_date = ri.recent_inventory_date
left join dorel_dwh.edw.dim_item di
on fi.item_sk = di.item_sk
left join walmart.components.dim_warehouse dw
on fi.warehouse_sk = dw.warehouse_sk
where 1=1
and fi.item_sk is not null -- don't want null item inventories
and inventory_date <=current_date() -- inventory date is the current or less
and di.model_number is not null -- some reason I don't have all the items numbers. unfortunate 
-- and is_current_quantity_flag = 'Y' -- maybe use this? sometimes there are inventory dates that are in the future by hundreds of years
group by 
   di.model_number
   -- ,fi.fact_sk
    ,fi.item_sk
    ,dw.warehouse_sk
    ,dw.warehouse_name
    ,dw.warehouse_number
    ,fi.inventory_date
    ,inventory_turns
    ,open_order_quantity
    ,on_water_quantity
    ,po_quantity
)
select * 
from ia
)