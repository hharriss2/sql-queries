--finds the % change of what the edr is predicted to sell at depending on the retail of an item.
--compare this with promo retails
create or replace view forecast.edr_percent_changes as 
(
with r as --retail link data
(-- shows units sold each day and their retail price rounded to the nearest 10
select item_id
	,sale_date
	,units
	,(((sales/nullif(units,0)) * .1)::numeric(10,0))* 10 as retail_price
	,date_part('year',sale_date) as sale_year
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
		then sale_date
		else null
		end as sale_date_2019
	,case
		when sale_year = 2020
		then sale_date
		else null
		end as sale_date_2020
	,case
		when sale_year = 2021
		then sale_date
		else null 
		end as sale_date_2021
	,case
		when sale_year = 2022
		then sale_date
		else null 
		end as sale_date_2022
	,case
		when sale_year = 2023
		then sale_date
		else null 
		end as sale_date_2023
	,case
		when sale_year = 2024
		then sale_date
		else null 
		end as sale_date_2024
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
	,count(distinct sale_date_2019) as total_sale_date_2019
	,count(distinct sale_date_2020) as total_sale_date_2020
	,count(distinct sale_date_2021) as total_sale_date_2021
	,count(distinct sale_date_2022) as total_sale_date_2022
	,count(distinct sale_date_2023) as total_sale_date_2023
	,count(distinct sale_date_2024) as total_sale_date_2024
from r_cond
group by item_id, retail_price
)
,r_agg_2 as --retail aggregate step 2
( --find the units per day for each year.
select 
	item_id
	,retail_price
	,total_units_2019/nullif(total_sale_date_2019,0) as total_units_per_day_2019
	,total_units_2020/nullif(total_sale_date_2020,0) as total_units_per_day_2020
	,total_units_2021/nullif(total_sale_date_2021,0) as total_units_per_day_2021
	,total_units_2022/nullif(total_sale_date_2022,0) as total_units_per_day_2022
	,total_units_2023/nullif(total_sale_date_2023,0) as total_units_per_day_2023
	,total_units_2024/nullif(total_sale_date_2024,0) as total_units_per_day_2024
	,max(total_sale_date_2023) over (partition by item_id) as max_sale_date_2023
	,total_sale_date_2023
	,max(total_sale_date_2024) over (partition by item_id) as max_sale_date_2024
	,total_sale_date_2024
from r_agg
where 1=1
and total_sale_date_2019
+total_sale_date_2020
+total_sale_date_2021
+total_sale_date_2022
+total_sale_date_2023
+total_sale_date_2024 >10
)
,r_agg_3 as
( -- looking at units per day & comparing to the upd for that every day retail
select 
	item_id
	,retail_price
	,total_units_per_day_2023
	,total_units_per_day_2024
	,max(case -- find the units per day when retail is the EDR retail for that year
		when max_sale_date_2023 = total_sale_date_2023
		then total_units_per_day_2023
		else null
		end) over(partition by item_id) as upd_edr_2023
	,max(case -- find the units per day when reail is the EDRO retail for 2024
		when max_sale_date_2024 = total_sale_date_2024
		then total_units_per_day_2024
		else null
		end) over(partition by item_id) as upd_edr_2024
from r_agg_2
)
,details as
(
select 
	item_id
	,retail_price
	,total_units_per_day_2023
	,(total_units_per_day_2023 - upd_edr_2023)::numeric(10,2)/nullif(upd_edr_2023,0) as edr_perc_change_2023
		,total_units_per_day_2024
	,(total_units_per_day_2024 - upd_edr_2024)::numeric(10,2)/nullif(upd_edr_2024,0) as edr_perc_change_2024
from r_agg_3
)
select
	item_id
	,retail_price
	,coalesce(edr_perc_change_2024, edr_perc_change_2023)::numeric(10,2) as edr_perc_change
from details
)
;
