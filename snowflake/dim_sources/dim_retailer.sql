create or replace table walmart.dim_sources.dim_retailer as 
(
select distinct
    dense_rank() over (order by retailer_name) as retailer_id
    ,retailer_name
from dorel_dwh.edw.dim_customer
)