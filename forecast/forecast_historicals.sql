insert into forecast.forecast_historicals
	(model
	, forecast_date
	, forecast_units_new--customer forecast
	, l4_units--ship unit metrics at the time
	, l12_units
	, ams_units
	)

with 
fac as 
	(
	select fa.model
	,forecast_date
	,units
	from forecast.forecast_agenda_customer fa
	where 1=1
	and fa.fcast_division_id =2
	and date_inserted::date =(--Finds the most current forecast. Switch to upload historicals
				select max(date_inserted::date) 
				from forecast.forecast_agenda_customer
						)
	and fa.forecast_date::text = to_char(now()::date + interval '1 month','YYYY-MM-01')
		/*For manual entry*/
		--use previous month date_inserted to upload target month forecast_date
--	and date_inserted::date = '2022-07-15'
--	and fa.forecast_date = '2022-08-01'
			/**/
	)
, ams as 
	(
	select * 
	from misc_views.ams_ships
	where model in (select model from forecast.forecast_agenda_customer)
	)
,fa as 
	(
	select fa.model, units, fa.forecast_date, date_inserted::date
	from forecast.forecast_agenda fa
	where 1=1
	and fa.fcast_division_id = 2
	and	fa.date_inserted::date=	
			(--Finds the most current forecast. Switch to upload historicals
			select max(date_inserted::date) 
			from forecast.forecast_agenda
			)
	and fa.forecast_date::text = to_char(now()::date + interval '1 month','YYYY-MM-01')	
			/*For manual entry*/
			--use previous month date_inserted to upload target month forecast_date
--	 and fa.date_inserted::date = '2022-07-01'
--	 and fa.forecast_date = '2022-08-01'
					/**/
	)
select fa.model
	,fac.forecast_date
	,case when fac.units =0 then fa.units
	else fac.units end as units
	,ams.l4_units_ships-- ship units at the time
	,ams.l12_units_ships
	,ams.ams_units
from fac
left join fa
on fa.model = fac.model
left join  ams
on fa.model = ams.model
	;
