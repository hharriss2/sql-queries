create or replace table walmart.components.customer_deductions
(
customer_deduction_id integer default walmart.components.customer_deduction_seq.nextval primary key
,costing_date date
,customer_number varchar(250)
,deduction_percent numeric(10,4)
,customer_deduction_comp_key varchar(250) unique
--ex customer_number || ' | '|| costing_date
,inserted_at timestamp_ntz default current_timestamp()
,updated_on timestamp_ntz
)

;

