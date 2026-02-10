--model for the budget table

create or replace table walmart.components.dhf_budget
(
budget_id integer default walmart.components.dhf_budget_seq.NEXTVAL PRIMARY KEY
,budget_date date
,customer_number varchar(100)
,sourcing_type varchar(50)
,model_number varchar(250)
,warehouse_number varchar(250)
,budget_units numeric(10,2)
,budget_sales numeric(10,2)
,budget_deductions numeric(10,2)
,deduction_percent numeric(10,4)
,variable_cost_pu numeric(10,2)
,material_cost_pu numeric(10,2)
,duty_cost_pu numeric(10,2)
,freight_cost_pu numeric(10,2)
,labor_cost_pu numeric(10,2)
,overhead_cost_pu numeric(10,2)
,royalties_total numeric(10,2)
,inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
,updated_on timestamp_ntz

)
;
--using a temp table to get the budget info in 
create or replace table walmart.public.temp_budget_table
(
budget_month varchar(250)
,customer_number varchar(100)
,sourcing_type varchar(50)
,model_number varchar(250)
,warehouse_number varchar(250)
,budget_units varchar(250)
,budget_sales varchar(250)
,budget_deductions varchar(250)
,deduction_percent varchar(250)
,variable_cost_pu varchar(250)
,material_cost_pu varchar(250)
,duty_cost_pu varchar(250)
,freight_cost_pu varchar(250)
,labor_cost_pu varchar(250)
,overhead_cost_pu varchar(250)
,royalties_total varchar(250)
)
;