--converts the forecast by month into wm date
create or replace view projections.updated_forecast_dhp_by_week as 
(
with fw as --forecast weeks
(
select model
	,forecast_date
	,units
	,w.wm_date
	,count(wm_date) over (partition by model, forecast_date) as total_wm_week
from forecast.forecast_dhp f
left join lookups.wm_week_to_month w
on f.forecast_date = w.first_date
and f.inserted_at = (select max(inserted_at) from forecast.forecast_dhp)
where 1=1
and w.wm_date is not null
)
select model
	,wm_date
	,units/total_wm_week as units_by_week
from fw
)
;
