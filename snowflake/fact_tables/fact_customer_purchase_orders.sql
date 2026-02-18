

--used on the dhf shipment power bi report. usually what people mean when they refer to purchase orders
create or replace view walmart.power_bi.fact_customer_purchase_orders as 
(
select
    date_requested
    ,transaction_date
    ,dcal.cal_id -- linked to the transaction date. people usually don't care about the date requested as far as DHF things go. 
    ,order_number
    ,hf_customer_number
    ,cbm_id
    ,warehouse_id
    ,dot.order_type_id
    ,pn.product_name_id
    ,last_status_code
    ,next_status_code
    ,units_transaction
    ,quantity_shipped
    ,price_per_unit
    ,gross_sales
    ,unit_cost_amount
    ,sales_cost
    ,standard_cost
    ,total_deduction_percent
    ,net_sales
    ,shipment_number
from walmart.core.customer_orders co
left join walmart.dim_sources.dim_order_type dot
on co.order_type = dot.order_type_name
left join walmart.dim_sources.dim_product_name pn
on co.product_name = pn.product_name
left join walmart.dim_sources.dim_calendar dcal
on transaction_date = dcal.cal_date
)
;


