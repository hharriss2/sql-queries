create or replace table WALMART.DIM_SOURCES.DIM_collection as 

(
select distinct collection as collection_name
    ,dense_rank() over (order by collection) as collection_id
from dorel_dwh.edw.dim_item
where collection is not null
)
;