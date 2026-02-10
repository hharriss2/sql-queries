--combining the dhf and jde shipment tables into a shipment view
create or replace view walmart.core.ships_details as 
(
with t1 as  -- non aggregated shipment data.
( --union the historical shipment source to the new one
select
    order_id as ship_id
    ,date_shipped
    ,retailer
    ,sale_type
    ,division
    ,units
    ,sales
    ,hf_customer_number
    ,brand
    ,warehouse_code as alternate_wh_number
from walmart.core.ships_jde
union all
select
    fact_sk as ship_id
    ,date_shipped
    ,retailer
    ,sale_type
    ,division
    ,units
    ,sales
    ,hf_customer_number
    ,brand
    ,alternate_wh_number
from walmart.core.ships_dhf
)
select  
    ship_id
    ,date_shipped
    ,retailer
    ,sale_type
    ,division
    ,units
    ,sales
    ,hf_customer_number
    ,brand
    ,alternate_wh_number
from t1
)
;