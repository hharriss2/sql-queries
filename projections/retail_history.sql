--retail history in progress
--trying to find the historical units for a reta
with r as --retail link data
(-- shows units sold each day and their retail price rounded to the nearest 10
select item_id
	,sale_date
	,units
	,(((sales/nullif(units,0)) * .1)::numeric(10,0))* 10 as retail_price
	,date_part('year',sale_date) as sale_year
    ,date_trunc('week',sale_date)::date as sale_week -- used to find # of unique weeks the item sold at specific retails
from retail_link_pos
where 1=1
and  units >0
and sales >0
-- and item_id = 46368984
)
,r_cond as --retail date conditional
(-- breaks out each date into its own column for counting the units & sales for that specific year
select 
	item_id
	,retail_price
	,sale_year
    ,sale_week
	,case
		when sale_year = 2019
		then units
		else 0
		end as units_2019
	,case
		when sale_year = 2020
		then units
		else 0
		end as units_2020
	,case
		when sale_year = 2021
		then units
		else 0 
		end as units_2021
	,case
		when sale_year = 2022
		then units
		else 0 
		end as units_2022
	,case
		when sale_year = 2023
		then units
		else 0 
		end as units_2023
	,case
		when sale_year = 2024
		then units
		else 0 
		end as units_2024
	,case
		when sale_year = 2019
		then sale_week
		else null
		end as sale_week_2019
	,case
		when sale_year = 2020
		then sale_week
		else null
		end as sale_week_2020
	,case
		when sale_year = 2021
		then sale_week
		else null 
		end as sale_week_2021
	,case
		when sale_year = 2022
		then sale_week
		else null 
		end as sale_week_2022
	,case
		when sale_year = 2023
		then sale_week
		else null 
		end as sale_week_2023
	,case
		when sale_year = 2024
		then sale_week
		else null 
		end as sale_week_2024
from r
where 1=1
)
,r_agg as -- retail aggregate 
( --finds the total units sold at each reatail for each year. Also finds total dates retail sold at that retail for
SELECT
	item_id
	,retail_price
	,sum(units_2019) as total_units_2019
	,sum(units_2020) as total_units_2020
	,sum(units_2021) as total_units_2021
	,sum(units_2022) as total_units_2022
	,sum(units_2023) as total_units_2023
	,sum(units_2024) as total_units_2024
	,count(distinct sale_week_2019) as total_sale_week_2019
	,count(distinct sale_week_2020) as total_sale_week_2020
	,count(distinct sale_week_2021) as total_sale_week_2021
	,count(distinct sale_week_2022) as total_sale_week_2022
	,count(distinct sale_week_2023) as total_sale_week_2023
	,count(distinct sale_week_2024) as total_sale_week_2024
from r_cond
group by item_id, retail_price
)
,r_agg_2 as --retail aggregate step 2
( --find the units per day for each year.
select 
	item_id
	,retail_price
	,total_units_2019/nullif(total_sale_week_2019,0) as total_units_per_week_2019
	,total_units_2020/nullif(total_sale_week_2020,0) as total_units_per_week_2020
	,total_units_2021/nullif(total_sale_week_2021,0) as total_units_per_week_2021
	,total_units_2022/nullif(total_sale_week_2022,0) as total_units_per_week_2022
	,total_units_2023/nullif(total_sale_week_2023,0) as total_units_per_week_2023
	,total_units_2024/nullif(total_sale_week_2024,0) as total_units_per_week_2024
	,max(total_sale_week_2023) over (partition by item_id) as max_sale_week_2023
	,max(total_sale_week_2024) over (partition by item_id) as max_sale_week_2024
	,total_units_2023
	,total_units_2024
	,total_sale_week_2023
	,total_sale_week_2024
from r_agg
where 1=1
and total_sale_week_2019
+total_sale_week_2020
+total_sale_week_2021
+total_sale_week_2022
+total_sale_week_2023
+total_sale_week_2024 >10
)
select * 
from r_agg_2
where item_id = '9864293';

;