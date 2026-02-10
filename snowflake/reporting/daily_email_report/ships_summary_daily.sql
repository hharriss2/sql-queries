--used for the pdf report daily send out. a query is created off of this to get the numbers and compare to budget
create or replace view walmart.reporting.ships_summary_daily as 
(
with ships_details as  -- non aggregated shipment data.
( --union the historical shipment source to the new one
select
    ship_id
    ,date_shipped
    ,retailer
    ,sale_type
    ,division
    ,units
    ,sales
    ,hf_customer_number
    ,brand
    ,alternate_wh_number
from walmart.core.ships_details
where date_shipped >=current_date() - interval '365 days'
)
,ships_summary as 
(
select 
    alternate_wh_number
    ,division
    ,hf_customer_number
    ,sale_type
    ,sum(
        case
        when date_part('year',date_shipped) = 2026
        then units
        else 0 end
        ) as total_2026_units
    ,sum(
        case
        when date_part('year',date_shipped) = 2025
        then units
        else 0 end
        ) as total_2025_units
    ,sum(
        case
        when date_part('year',date_shipped) = 2026
        then sales
        else 0 end
        ) as total_2026_sales
    ,sum(
        case
        when date_part('year',date_shipped) = 2025
        then sales
        else 0 end
        ) as total_2025_sales
    ,sum(
        case
        when dcal.is_ytd_ey = 1 and date_part('year',date_shipped) = 2026
        then units
        else 0 end
        ) as ytd_2026_units
    ,sum(
        case
        when dcal.is_ytd_ey = 1 and date_part('year',date_shipped) = 2025
        then units
        else 0 end
        ) as ytd_2025_units
    ,sum(
        case
        when dcal.is_ytd_ey = 1 and date_part('year',date_shipped) = 2026
        then sales
        else 0 end
        ) as ytd_2026_sales
    ,sum(
        case
        when dcal.is_ytd_ey = 1 and date_part('year',date_shipped) = 2025
        then sales
        else 0 end
        ) as ytd_2025_sales
    ,sum(
        case
        when dcal.is_mtd_ey = 1 and date_part('year',date_shipped) = 2026
        then sales
        else 0 end
        ) as mtd_2026_sales
    ,sum(
        case
        when dcal.is_mtd_ey = 1 and date_part('year',date_shipped) = 2025
        then sales
        else 0 end
        ) as mtd_2025_sales
from ships_details s
join walmart.dim_sources.dim_calendar dcal
on s.date_shipped = dcal.cal_date
group by all
)
select * 
from ships_summary
)