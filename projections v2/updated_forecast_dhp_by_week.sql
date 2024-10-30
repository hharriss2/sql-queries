select * 
from projections.projected_units_by_week_mat_view
limit 10000
;

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
on date_part('month',f.forecast_date) = w.first_month_num
and date_part('year',f.forecast_date) = w.wm_year
and f.inserted_at = (select max(inserted_at) from forecast.forecast_dhp)
)
select model
	,wm_date
	,units/total_wm_week as units_by_week
from fw
)
;
