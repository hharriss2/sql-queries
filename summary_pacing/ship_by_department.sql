--query that is executed to popualate postgres table summary_pacing.ship_by_department
select
    cbm.department
    ,date_trunc('month',date_shipped) as month_shipped
    ,sum(sales) as total_sales
from walmart.core.ships_details sd
left join walmart.dim_sources.dim_cat_by_model cbm
on sd.model = cbm.model
where 1=1
and date_shipped >='2025-01-01'
and warehouse_country in ('US','CA','USA')
group by all
having total_sales >0
;
