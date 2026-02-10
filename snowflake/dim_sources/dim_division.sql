create table walmart.dim_sources.dim_division as 
(
select distinct 
    dense_rank() over (order by division_name) as division_id
    ,division_name
    , division_code
from dorel_dwh.edw.dim_item
where division_name is not null
)