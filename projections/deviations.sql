--find the last 4,13, & 52 weeks for ships
--find deviations.
--depending on how much deviation, adjust weights for the units
create or replace view projections.deviation as
(
with s as 
(
select
	model
	,date_shipped
	,units
	,case
		when date_shipped >= date_trunc('month',current_date - interval '13 months')
		and date_trunc('month',date_shipped) !=  date_trunc('month',current_date)
		then 1 else 0
		end as is_ams -- boolean to show last 52 weeks sold
	,case
		when date_shipped >= date_trunc('week', current_date - interval '5 weeks')
		and date_trunc('week',date_shipped) !=date_trunc('week',current_date)
		then 1
		else 0
		end as is_l4 -- boolean to show last 4 weeks sold
	,case
		when date_shipped >= date_trunc('week', current_date - interval '13 weeks')
		and date_trunc('week',date_shipped) !=date_trunc('week',current_date)
		then 1
		else 0
		end as is_l12 -- boolean to show if is last 12 for units sold
from ships_schema.ships s 
where 1=1
and date_shipped >=current_date - interval '14 months'
and retailer ='Walmart.com'
and sale_type = 'Drop Ship'
)
,s_agg as --ships aggregate
( -- finding the average units sold for 12 months, 12 weeks, 4 weeks
select
	model
	,sum( -- avg monthly units for last 12 months. divide by 12
		case
		when is_ams = 1
		then units
		else 0
		end)/12 as ams_units 
	,sum( -- find the average monthly units for last 12 weeks. divide by 3
		case
		when is_l12 = 1
		then units
		else 0
		end)/3 as l12_units_ships
	,sum(--avg monthly units for last 4 weeks. don't divide bc 4 weeks represent a month
		case
		when is_l4 = 1
		then units
		else 0
		end) as l4_units_ships
	,stddev( -- finding standard deviation for the units sold during each of the periods. 
		case
		when is_ams =1
		then units
		else null
		end) as ams_dev
	,stddev(
		case
		when is_l12 = 1
		then units
		else null
		end) as l12_dev
	,stddev(
		case
		when is_l4 = 1
		then units
		else null
		end) as l4_dev
	--set the weighted average variables here
	,.2 as ams_weight
	,.5 as l4_weight
	,.3 as l12_weight
from s
group by model
)
select model
	,l4_units_ships::numeric(10,2) as l4_units_ships
	,l12_units_ships::numeric(10,2) as l12_units_ships
	,ams_units::numeric(10,2) as ams_units
--	,l4_dev::numeric(10,2)
--	,l12_dev::numeric(10,2)
--	,ams_dev::numeric(10,2)
	,l4_weight
	,l12_weight
	,ams_weight
	,case when l4_dev+.15 >= ams_dev then l4_weight -.1
		when l4_dev+.1 >= l12_dev then l4_weight -.1
		when l4_dev +.15 <= ams_dev then l4_weight +.1
		when l4_dev +.1 <= l12_dev then l4_weight +.1
		else l4_weight end as l4_weight_adj_dev
	,case when l4_dev+.15 >= ams_dev then l12_weight
		when l4_dev+.1 >= l12_dev then l12_weight +.1
		when l4_dev +.1 <=l12_dev then l12_weight -.1
		else l12_weight end as l12_weight_adj_dev
	,case when l4_dev +.15<= ams_dev and l4_dev +.1 >= l12_dev then ams_weight
		when l4_dev +.15 >= ams_dev then ams_weight +.1
		when l4_dev +.15 <=ams_dev then ams_weight -.1
		else ams_weight end as ams_weight_adj_dev
	,case when l4_units_ships *2 >= ams_units then l4_weight -.1
		when l4_units_ships * 1.5 >= l12_units_ships then l4_weight -.1
		when l4_units_ships *2 <=ams_units and  l4_units_ships *1.5 <=l12_units_ships then l4_weight +.2
		when l4_units_ships * 2 <= ams_units then l4_weight +.1
		when l4_units_ships * 1.5 <= l12_units_ships then l4_weight +.1
		else l4_weight end as l4_weight_adj
	,case when l4_units_ships *2 >= ams_units then l12_weight
		when l4_units_ships *1.5 >= l12_units_ships then l12_weight +.1
		when l4_units_ships *1.5 <=l12_units_ships then l12_weight -.1
		else l12_weight end as l12_weight_adj
	,case when l4_units_ships *2 <= ams_units and l4_units_ships *1.5 >= l12_units_ships then ams_weight +.1
		when l4_units_ships *2 >= ams_units then ams_weight +.1
		when l4_units_ships *2 <=ams_units then ams_weight -.1
		else ams_weight end as ams_weight_adj
from s_agg
)
;		
