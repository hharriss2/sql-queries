--final view for the projections
create or replace view projections.projection_view as 
(
with fu as 
(--forecast units
	--has all of the calculations for forecasted units
	select * 
	from projections.forecasted_units_raw
)
,mf as 
(--model final
	--has model sales averaged through the years for each month
	select *
	from forecast.model_final
)
,mfs as 
(--model final sum
	--sums all of the models sales to find a % for the month on how many units should be allocated
	select model, sum(total_units) as total_units
	from mf
	group by model
)
,mff as 
(--model final final
 --joins on sum of units from model final to get a ratio of the units
	select t1.model, t1.month_num, (t1.total_units / t2.total_units)::numeric(10,2) as model_ratio
	from mf t1
	join mfs t2
	on t1.model = t2.model
)
, fus as 
(--forecast units sum
	--sums all of the forecasted units
	select model,sum(forecasted_units) as forecasted_units_total
	from fu
	group by model
)
--forecasted amount summed is mulitiplied by model ratio to distribute units accordingly
select fu.fcast_units_id, fu.model,fu.sub_cat, fu.month_num, (forecasted_units_total * model_ratio)::numeric(10,2) as forecasted_units
from fu
join mff
on fu.model = mff.model and fu.month_num = mff.month_num
join fus
on fus.model = mff.model
)
;