create or replace view WALMART.DIM_SOURCES.DIM_BRANDS as (
    
select distinct brand as brand_name
    ,dense_rank() over (order by brand) as brand_id
from dorel_dwh.edw.dim_item
)
;