create table walmart.dim_sources.dim_customer as 
(

select
    dense_rank() over (order by customer_nk) as customer_id
    ,customer_nk as customer_number
    ,customer_name
from dorel_dwh.edw.dim_customer
)