--query that is executed to popualate postgres table summary_pacing.ship_by_customer
select
    sd.hf_customer_number
    ,date_trunc('month',date_shipped) as month_shipped
    ,sum(sales) as total_sales
from walmart.core.ships_details sd
where 1=1
and date_shipped >='2025-01-01'
and warehouse_country in ('US','CA','USA')
group by all
;
