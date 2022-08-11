create view forecast.forecast_update_old_units as 
(--used in the update_forcast_historical() python function. have to put this in a view to run it in  update statement
 select fa.model, fa.forecast_date, fa.date_inserted::date, sum(units)
    from forecast.forecast_agenda fa
    group by fa.model, fa.forecast_date, fa.date_inserted
);