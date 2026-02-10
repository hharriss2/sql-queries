create or replace table walmart.dim_sources.dim_sales_type as 
(
select distinct 
    dense_rank() over (order by sales_type) as sales_type_id
    ,sales_type
from dorel_dwh.edw.dim_customer
)
;
