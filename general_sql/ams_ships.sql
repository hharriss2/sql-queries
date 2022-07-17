 create or replace view misc_views.ams_ships as (		
select l52_units_sold.model
	,ams_units
	,l4_units_ships
	,l12_units_ships
from 
	(
	select s.model
	, (sum(units)/count(distinct to_char(date_shipped, 'YYYYMM'))::numeric(10,2))::numeric(10,2) ams_units
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
;
