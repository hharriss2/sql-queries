--budget summary is used to query off of to get the sales numbers for the daily report send out 
create or replace view walmart.reporting.budget_summary_daily as 
(
with budget_details as 
( -- detailed info on the budget table
select 
    budget_date
    ,cbm.division_name
    ,mrl.hf_pricing_type as sale_type
    ,warehouse_number
    ,customer_number
    ,budget_units
    ,budget_sales
from walmart.components.dhf_budget b
left join walmart.dim_sources.dim_cat_by_model cbm
on b.model_number = cbm.model
left join walmart.components.monday_retailer_list mrl
on b.customer_number = mrl.hf_customer_number
)
,budget_summary as --aggregating budget numbers
(
    select
    budget_date
    ,warehouse_number
    ,division_name
    ,customer_number
    ,sale_type
    ,sum(
        case
        when date_part('year',budget_date) = 2026
        then budget_units
        else 0 end
        ) as total_2026_budget_units
    ,sum(
        case
        when date_part('year',budget_date) = 2026
        then budget_sales
        else 0 end
        ) as total_2026_budget_sales
    ,sum( -- will add this number to the finished week to date after
        case
        when dcal.is_ytd_ey = 1 and date_part('year',budget_date) = 2026
            and budget_date != date_trunc('month',current_date())
        then budget_sales
        else 0 end
        ) as ytd_2026_budget_sales_step_1
    ,sum( -- this is the current months total budget
        case
        when dcal.is_mtd_ey = 1 and date_part('year',budget_date) = 2026
        then budget_sales 
        else 0 end
        ) as current_month_2026_budget_sales
from budget_details bd
join walmart.dim_sources.dim_calendar dcal
on bd.budget_date = dcal.cal_date
group by all
)
select * 
from budget_summary
)