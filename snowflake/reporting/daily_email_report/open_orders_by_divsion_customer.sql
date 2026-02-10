--view to power automated reporting to view open orders for the day 
create or replace view walmart.reporting.open_orders_by_division_customer as 
(
select
    division_name
    ,customer_name
    ,sum(units_transaction)::numeric(10,0) as quantity_transacted
    ,sum(quantity_shipped)::numeric(10,0) as quantity_shipped
    ,sum(gross_sales) as gross_sales
    ,sum(standard_cost) as standard_cost
    ,sum(net_sales) as net_sales
from walmart.core.customer_orders wo
where date_requested >= current_date() - 1
and date_requested <=current_date()

group by all
order by division_name , customer_name
)
;

