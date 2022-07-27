/*PROCESS FOR UPLOADING FORECAST HISTORICALS*/

truncate forecast.forecast_historicals;
--run after uploading customer forecast
insert into forecast.forecast_historicals
	(model
	, forecast_date
	, forecast_units_old--adjusted forecast
	, forecast_units_new--customer forecast
	, l4_units--ship unit metrics at the time
	, l12_units
	, ams_units)
--query puts together the adjuted and customer forecast for the month
select
	fa.model
	,fa.forecast_date
	,fa.units as forecast_units-- adjusted forecast
	,case --if customer forecast is 0, then use adjusted forecast
		 when fac.units = 0 then fa.units
		 else fac.units 
		 end as fcast_units_customer
	,ams.l4_units_ships-- ship units at the time
	,ams.l12_units_ships
	,ams.ams_units
from forecast.forecast_agenda fa
join (--JOIN CUSTOMER FORECAST 
	  select * 
	  from forecast.forecast_agenda_customer
	  where date_inserted::date =(
	  					select max(date_inserted::date) 
	  					from forecast.forecast_agenda_customer
	  							)
	  ) fac
on fa.model = fac.model and fa.forecast_date = fac.forecast_date
join misc_views.ams_ships ams on ams.model = fa.model
where fa.date_inserted::date =(select max(date_inserted::date) from forecast.forecast_agenda)
and date_part('year',fa.forecast_date)::text || date_part('month',fa.forecast_date) = date_part('year',now())::text || date_part('month',now());