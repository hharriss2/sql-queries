create or replace table walmart.dim_sources.dim_retailer_type as 
(
select distinct 
    dense_rank() over (order by retailer_type) as retailer_type_id
    ,retailer_type
from dorel_dwh.edw.dim_customer
)
;
