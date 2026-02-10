create or replace table walmart.dim_sources.dim_retailer_group as 
(
select distinct 
    dense_rank() over (order by retailer_group) as retailer_group_id
    ,retailer_group
from dorel_dwh.edw.dim_customer
)
;
