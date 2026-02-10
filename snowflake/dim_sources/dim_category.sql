create or replace table walmart.dim_sources.dim_category as 
(
select distinct category_name
    ,dense_rank() over (order by category_name) as category_id
from dorel_dwh.edw.dim_item
where category_name is not null)
;