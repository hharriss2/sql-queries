create or replace view WALMART.DIM_SOURCES.DIM_WAREHOUSE as 
(
select
    dense_rank() over (order by warehouse_sk) as warehouse_id
    ,warehouse_sk
    ,warehouse_number
    ,warehouse_name
    ,warehouse_group_name
    ,warehouse_city
    ,warehouse_state
    ,warehouse_postal_code
    ,warehouse_country
from dorel_dwh.edw.dim_warehouse
)
;