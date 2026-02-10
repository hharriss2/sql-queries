create or replace table walmart.dim_sources.dim_value_class as 
(
select distinct 
    dense_rank() over (order by value_class) as value_class_id
    ,value_class
from dorel_qlik_migration.reporting.margin_actuals
)