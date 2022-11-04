--deviation forecast piece
--lived in forecast table in forecast.forecasted_units

create or replace view projections.deviation as
(

	select l52_units_sold.model
	,l4_units_ships
	,l12_units_ships
	,ams_units	
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
	from 
		(
		select s.model
		, (sum(units)/count(distinct to_char(date_shipped, 'YYYYMM'))::numeric(10,2))::numeric(10,2) ams_units
		,stddev(units) ams_dev
		,.2 as ams_weight
		from ships_schema.ships s
			where to_char(date_shipped, 'YYYYMM') in 
				(-- find year/month for last 12 months minus the current month 
					select distinct to_char(date_shipped, 'YYYYMM')
					from ships_schema.ships 
					where to_char(date_shipped, 'YYYYMM') != (
												select to_char(max(date_shipped),'YYYYMM') 
												from ships_schema.ships
															 )
					order by to_char(date_shipped, 'YYYYMM') desc
					limit 12
						)
			and retailer ='Walmart.com'
			group by s.model
		)l52_units_sold
	left join 
		(
		select s.model
		, (sum(units)::numeric(10,2))::numeric(10,2) l4_units_ships
		,stddev(units) l4_dev
		,.5 as l4_weight
		-- not divided because last 4 acts as true month sum
		from ships_schema.ships s
		join wm_calendar w
		on s.date_shipped = w.date
		where wm_date in (-- finds the last 4 full weeks of sales
							select distinct w.wm_date
							from ships_schema.ships s
							join wm_calendar w
							on s.date_shipped = w.date
							where wm_date != (select max(w.wm_date)-- filtes non full week
							from ships_schema.ships s join wm_calendar w on s.date_shipped = w.date)
							order by wm_date desc
							limit 4
						)
		and units >0
		and retailer ='Walmart.com'
		group by s.model
		)l4_units_sold
	on l52_units_sold.model = l4_units_sold.model
	left join 
		(
		select s.model
		, (sum(units)/3::numeric(10,2))::numeric(10,2) l12_units_ships
		,stddev(units) l12_dev
		,.3 as l12_weight
		-- divided by 3 to show an month average
		from ships_schema.ships s
		join wm_calendar w
		on s.date_shipped = w.date
		where wm_date in (-- finds the last 12 full weeks of sales
							select distinct w.wm_date
							from ships_schema.ships s
							join wm_calendar w
							on s.date_shipped = w.date
							where wm_date != (select max(w.wm_date)-- filtes non full week
							from ships_schema.ships s join wm_calendar w on s.date_shipped = w.date)
							order by wm_date desc
							limit 12
						)
		and units >0
		and retailer = 'Walmart.com'
		group by s.model
		)l12_units_sold
	on l12_units_sold.model = l52_units_sold.model
	where ams_units >0 
)
