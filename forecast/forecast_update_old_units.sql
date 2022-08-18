create view forecast.forecast_update_old_units as 
(--used in the update_forcast_historical() python function. have to put this in a view to run it in  update statement
 select fa.model, fa.forecast_date, fa.date_inserted::date, sum(units)
    from forecast.forecast_agenda fa
    group by fa.model, fa.forecast_date, fa.date_inserted
);

--updates ams for pas historicals
update forecast.forecast_historicals t1
set l4_units = t2.l4_units_ships
from forecast.ams_staging t2
where t1.model = t2.model
and t1.forecast_date = t2.forecast_date;
update forecast.forecast_historicals t1
set l12_units = t2.l12_units_ships
from forecast.ams_staging t2
where t1.model = t2.model
and t1.forecast_date = t2.forecast_date;
update forecast.forecast_historicals t1
set ams_units = t2.ams_units
from forecast.ams_staging t2
where t1.model = t2.model
and t1.forecast_date = t2.forecast_date;
--check dupes
select *
from forecast.forecast_agenda fa
join 
	(
	select split_part(cc,';',1) as model, split_part(cc,';',2)::date as date_key
	from(
	select model||';'||forecast_date||';'||fcast_type_id as cc
	from forecast.forecast_historicals
	--where fcast_division_id = 1
	)t1
	group by cc
	having count(cc) >1
	)
t2
on fa.model = t2.model and fa.forecast_date = t2.date_key and fa.date_inserted::date = t2.date_key ;