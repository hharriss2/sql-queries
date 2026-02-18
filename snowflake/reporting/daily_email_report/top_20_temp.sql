-- brennan asked for a top 20 list for the retailers in walmart for the past 20 years. keeping in case this ask comes up again
-- create table walmart.public.temp_top_20  as (
insert into walmart.public.temp_top_20
(
model
,product_name
,brand
,division
,category
,department
,year_shipped
,total_units
,total_sales
)
select
model
,product_name
,brand
,division
,category
,department
,date_part('year',date_shipped) as year_shipped
,sum(units) as total_units
,sum(sales) as total_sales
from walmart.core.ships_jde
where 1=1
and date_part('year',date_shipped) =2026
group by all
order by total_sales desc

-- )
-- ;
;

with s2022 as 
(
select *
,1 as is_top_20_2022
from walmart.public.temp_top_20
where 1=1
and year_shipped = 2022
order by total_sales  desc
limit 20
)
,s2023 as 
(
select *
,1 as is_top_20_2023
from walmart.public.temp_top_20
where 1=1
and year_shipped = 2023
order by total_sales  desc
limit 20

)
,s2024 as 
(
select *
,1 as is_top_20_2024
from walmart.public.temp_top_20
where 1=1
and year_shipped = 2024
order by total_sales  desc
limit 20

)
,s2025 as 
(

select *
,1 as is_top_20_2025
from walmart.public.temp_top_20
where 1=1
and year_shipped = 2025
order by total_sales  desc
limit 20
)
,s2026 as 
(
select *
,1 as is_top_20_2026
from walmart.public.temp_top_20
where 1=1
and year_shipped = 2026
order by total_sales  desc
limit 20
)
select
    cbm.model
,cbm.product_name
,cbm.category
,cbm.department
,cbm.brand_name
,cbm.is_go_forward
,s2022.total_units as total_units_2022
,s2022.total_sales as total_sales_2022
,s2023.total_units as total_units_2023
,s2023.total_sales as total_sales_2023
,s2024.total_units as total_units_2024
,s2024.total_sales as total_sales_2024
,s2025.total_units as total_units_2025
,s2025.total_sales as total_sales_2025
,s2026.total_units as total_units_2026
,s2026.total_sales as total_sales_2026
,coalesce(is_top_20_2022,0)
+coalesce(is_top_20_2023,0)
+coalesce(is_top_20_2024,0)
+coalesce(is_top_20_2025,0)
+coalesce(is_top_20_2026,0) as top_item_counter
from walmart.dim_sources.dim_cat_by_model cbm
left join s2022
on cbm.model = s2022.model
left join s2023
on cbm.model = s2023.model
left join s2024
on cbm.model = s2024.model
left join s2025
on cbm.model = s2025.model
left join s2026
on cbm.model = s2026.model
where coalesce(is_top_20_2022,0)
+coalesce(is_top_20_2023,0)
+coalesce(is_top_20_2024,0)
+coalesce(is_top_20_2025,0)
+coalesce(is_top_20_2026,0)>=1