create or replace table walmart.dim_sources.dim_sub_category as 
(
select distinct subcategory_name as sub_category_name
    ,dense_rank() over (order by subcategory_name) as sub_category_id
from dorel_dwh.edw.dim_item
where subcategory_name is not null)
;