--used to update the walmart.components.item_costing table
create or replace view walmart.dei_dev.item_costing_historical_view as 
(
with t1 as 
(
select distinct
    "model" as model_number
    ,date_trunc('month',date)::date as costing_date
    ,customer_key as customer_number
    ,warehouse as warehouse_number
    ,(DEDUCTIONS/ gross_sales)::numeric(12,4) as deduction_percent
    ,(variable_product_cost / units_sold)::numeric(10,4) as variable_cost_pu
    ,material_cost / units_sold as material_cost_pu
    ,duty_cost / units_sold as duty_cost_pu
    ,freight_cost / units_sold as freight_cost_pu
    ,labor_cost / units_sold as labor_cost_pu
    ,overhead_cost / units_sold as overhead_cost_pu
    ,model_number ||' | ' || warehouse_number || ' | ' || customer_key ||' | ' ||' | '||  costing_date as comp_key
from dorel_qlik_migration.reporting.margin_actuals
-- where date >='2022-01-01'
)
select
    costing_date
    ,model_number
    ,warehouse_number
    ,customer_number
    ,deduction_percent
    ,variable_cost_pu
    ,material_cost_pu
    ,duty_cost_pu
    ,freight_cost_pu
    ,labor_cost_pu
    ,overhead_cost_pu
    ,current_timestamp() as updated_on
    ,comp_key
from t1
where comp_key is not null
)
;