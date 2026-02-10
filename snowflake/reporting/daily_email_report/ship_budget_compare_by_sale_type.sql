create or replace view walmart.reporting.ship_budget_compare_by_sale_type as 
(
with st as  -- sale type
(
select distinct hf_pricing_type as sale_type
from walmart.components.monday_retailer_list
where hf_pricing_type is not null

)
,st_ships as 
(
select
    sale_type
    ,sum(total_2026_sales) as total_2026_sales
    ,sum(ytd_2026_sales) as ytd_2026_sales
    ,sum(mtd_2026_sales) as mtd_2026_sales
from walmart.reporting.ships_summary_daily
group by sale_type
)
,cal_day as 
(
select total_days_in_month
from walmart.dim_sources.dim_calendar
where cal_date = current_date() - interval '1 day'
)
,st_budget_s1 as  -- sale type budget step 1. next and final step si updating the ytd and mtd number
(
select
    sale_type
    ,sum(total_2026_budget_sales) as total_2026_budget_sales
    ,sum(ytd_2026_budget_sales_step_1) as ytd_2026_budget_sales_step_1
    ,sum(current_month_2026_budget_sales) as current_month_2026_budget_sales
    ,cal_day.total_days_in_month
from walmart.reporting.budget_summary_daily
join cal_day
on 1=1
group by all
)
,st_budget as 
( -- finalizing the budget totals by sale type
select 
    sale_type
    ,total_2026_budget_sales
    ,current_month_2026_budget_sales
    --mtd calc
        ---- since it's full month, take (MTD * day # we're on)/ (days in month)
    ,(current_month_2026_budget_sales * date_part('day',current_date())  ) 
        / total_days_in_month
        as mtd_2026_budget_sales
    --previous YTD excluded the current month. adding the MTD here
    ,ytd_2026_budget_sales_step_1 + mtd_2026_budget_sales as ytd_2026_budget_sales
from st_budget_s1
where total_2026_budget_sales !=0
)
select
    st.sale_type
    --year to date
    ,coalesce(sts.ytd_2026_sales,0) as ytd_2026_sales
    ,coalesce(stb.ytd_2026_budget_sales,0) as ytd_2026_budget_sales
    --budget to date % of total 
    ,coalesce(sts.ytd_2026_sales / nullif(stb.ytd_2026_budget_sales,0),0) as ytd_percent_to_budget
    --month to date
    ,coalesce(sts.mtd_2026_sales,0) as mtd_2026_sales
    ,coalesce(stb.mtd_2026_budget_sales,0) as mtd_2026_budget_sales
    ,coalesce(sts.mtd_2026_sales / nullif(stb.mtd_2026_budget_sales,0),0) as mtd_percent_to_budget
    --^compares month to date sales to month to date budget percent 
    ,coalesce(stb.current_month_2026_budget_sales,0) as current_months_budget
    ,coalesce(sts.mtd_2026_sales / nullif(stb.current_month_2026_budget_sales,0),0) as percent_to_current_months_budget
    ,coalesce(stb.total_2026_budget_sales,0) as total_2026_budget_sales
    --^compares current month to date sales to the total budget for the month
from st
left join st_ships sts
on st.sale_type = sts.sale_type
left join st_budget stb
on st.sale_type = stb.sale_type
where 1=1
and coalesce(stb.total_2026_budget_sales,0) + coalesce(sts.ytd_2026_sales,0) !=0
)
;

