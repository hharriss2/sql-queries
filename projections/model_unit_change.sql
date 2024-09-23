--compares the avg number of units sold by month for each model number
--also shows total units sold for each month between 2019-2024
create or replace view projections.model_unit_average as
(
with s as  --ships
( --find the units shipped by model for each month-year
select 
	model
	,date_trunc('month',date_shipped)::date as month_year
	,date_part('year',date_shipped) as sale_year
	,date_part('month',date_shipped) as sale_month
	
	, sum(units) as total_units
from ships_schema.ships
where units >0
and date_shipped not between '2020-01-01' and '2020-12-31'
and retailer = 'Walmart.com'
and sale_type = 'Drop Ship'

group by model
	,date_trunc('month',date_shipped)::date
	,date_part('year',date_shipped)
	,date_part('month',date_shipped)
)
,s_1 as  --ships step 1
( -- find the std deviation & avg units shipped by model & shipping month
select 
	*
	,coalesce(stddev(total_units) over (partition by model, sale_month),0) as month_std
	,avg(total_units) over (partition by model, sale_month) as month_avg
from s
)
,details as  
(-- months have crazy outliars for the units. 
--use standard deviation to omit outliars ( avg +- stdev)
select
	model
	,month_year
	,sale_year
	,sale_month
	,total_units
	,case 
		when total_units <=month_avg +month_std
		and total_units >=month_avg - month_std
		then 0
		else 1
		end as is_units_outliar
from s_1
)
--final part
--find the 
select
	model
	,sale_month as month_num
	,avg(
		case
		when is_units_outliar =1
		then null
		else total_units
		end
	)::numeric(10,2) as total_units -- total units after adjusting for outliars
	,avg(total_units) as total_units_original  -- total units withought adjusting
	,stddev(total_units)::numeric(10,2) as stddev_units -- standard deviation for totaled units 
	,sum(
		case
		when sale_year = 2019
		then total_units
		else 0 
		end
	) as total_units_2019
	,sum(
		case
		when sale_year = 2020
		then total_units
		else 0 
		end
	) as total_units_2020
	,sum(
		case
		when sale_year = 2021
		then total_units
		else 0 
		end
	) as total_units_2021
	,sum(
		case
		when sale_year = 2022
		then total_units
		else 0 
		end
	) as total_units_2022
	,sum(
		case
		when sale_year = 2023
		then total_units
		else 0 
		end
	) as total_units_2023
	,sum(
		case
		when sale_year = 2024
		then total_units
		else 0 
		end
	) as total_units_2024
from details
group by model, sale_month
)
;

