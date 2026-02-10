--view for snowflake that alters the raw data in teh staging table for production
create or replace view walmart.dei_dev.budget_staging_view as 
(
with t1 as 
(select 
case
    when budget_month = 'Jan' 
        then '2026-01-01'
    when budget_month = 'Feb' 
        then '2026-02-01'
    when budget_month = 'Mar' 
        then '2026-03-01'
    when budget_month = 'Apr' 
        then '2026-04-01'
    when budget_month = 'May' 
        then '2026-05-01'
    when budget_month = 'Jun' 
        then '2026-06-01'
    when budget_month = 'Jul' 
        then '2026-07-01'
    when budget_month = 'Aug' 
        then '2026-08-01'
    when budget_month = 'Sep' 
        then '2026-09-01'
    when budget_month = 'Oct' 
        then '2026-10-01'
    when budget_month = 'Nov' 
        then '2026-11-01'
    when budget_month = 'Dec' 
        then '2026-12-01'
    else null 
    end as budget_date
    ,customer_number
    ,sourcing_type
    ,case
        when model_number like '00%'
        then right(model_number,length(model_number)-2)
        else model_number
        end as model_number
    ,warehouse_number
    ,budget_units::integer as budget_units
    ,budget_sales::numeric(10,2) as budget_sales
    ,budget_deductions::numeric(10,2) as budget_deductions
    ,deduction_percent::numeric(10,4) as deduction_percent
    ,variable_cost_pu::numeric(10,4) as variable_cost_pu
    ,material_cost_pu::numeric(10,4) as material_cost_pu
    ,labor_cost_pu::numeric(10,4) as labor_cost_pu
    ,duty_cost_pu::numeric(10,4) as duty_cost_pu
    ,freight_cost_pu::numeric(10,4) as freight_cost_pu
    ,overhead_cost_pu::numeric(10,4) as overhead_cost_pu
    ,royalties_total::numeric(10,2) as royalties_total
from walmart.public.temp_budget_table
)
select * 
from t1
)