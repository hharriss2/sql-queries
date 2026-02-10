create or replace table walmart.components.item_costing_2
(
item_costing_id integer default walmart.components.item_costing_seq.NEXTVAL PRIMARY KEY
,costing_date date
,model_number varchar(250)
,warehouse_number varchar(250)
,customer_number varchar(250)
,deduction_percent numeric(12,4)
,variable_cost_pu numeric(10,2)
,material_cost_pu numeric(10,2)
,duty_cost_pu numeric(10,2)
,freight_cost_pu numeric(10,2)
,labor_cost_pu numeric(10,2)
,overhead_cost_pu numeric(10,2)
,royalties_total numeric(10,2)
,inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
,updated_on timestamp_ntz
,item_costing_comp_key varchar(250)  not null unique
--,model_number ||' | ' || warehouse_number || ' | ' || customer_key ||' | ' ||' | '||  costing_date as comp_key
--mix of model, warehouse, and costing month
--ex model_num | wh number | 2026-01-01

)
;


/*used to insert the historical item costs */
insert into walmart.components.item_costing_2
(
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
    ,updated_on
    ,item_costing_comp_key

)
select 
    costing_date
    ,model_number
    ,warehouse_number
    ,customer_number
    ,deduction_percent
    ,variable_cost_pu
    ,coalesce(material_cost_pu,0)
    ,coalesce(duty_cost_pu,0)
    ,coalesce(freight_cost_pu,0)
    ,coalesce(labor_cost_pu,0)
    ,coalesce(overhead_cost_pu,0)
    ,updated_on
    ,comp_key
from walmart.dei_dev.item_costing_historical_view
where comp_key is not null
;


/*inserting the new item cost via budget sheet provided by jaasmeet */
insert into walmart.components.item_costing_2
(
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
    ,royalties_total
    ,updated_on
    ,item_costing_comp_key
)
select distinct
    budget_date
    ,model_number
    ,warehouse_number
    ,customer_number
    ,deduction_percent
    ,variable_cost_pu
    ,coalesce(material_cost_pu,0)
    ,coalesce(duty_cost_pu,0)
    ,coalesce(freight_cost_pu,0)
    ,coalesce(labor_cost_pu,0)
    ,coalesce(overhead_cost_pu,0)
    ,case
        when royalties_total is null then null
        when royalties_total = 0 then null
        
        else .04
        end
    ,current_timestamp()
    ,model_number ||' | ' || warehouse_number || ' | ' || customer_number ||' | ' ||' | '||  budget_date
from walmart.components.dhf_budget

;