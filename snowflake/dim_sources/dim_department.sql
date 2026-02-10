create or replace view WALMART.DIM_SOURCES.DIM_DEPARTMENT as (

(
select distinct department_name
    ,department_code
    ,dense_rank() over (order by department_name) as department_id
from dorel_dwh.edw.dim_item
where department_name is not null
)
;