create or replace table walmart.dim_sources.dim_product_name as
(
with t1 as 
(
select distinct item_name as product_name
from dorel_dwh.edw.dim_item
union all 
select distinct product_name_detailed as product_name
from walmart.core.margin_actuals
)
select distinct
    dense_rank() over (order by product_name) as product_name_id
    ,product_name
from t1
)
;