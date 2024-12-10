create or replace view forecast.wm_forecast_stores_view as 
(
with wf as --walmart forecast
(
select * 
from forecast.wm_forecast_stores
)
,rf as --recent forecast
(
select * 
from wf
where inserted_at = (select max(inserted_at) from wf)
)
,pf as --previous forecasat
(
select * 
from wf
where inserted_at = (
	select max(inserted_at) 
	from wf 
	where inserted_at !=(select max(inserted_at) from wf))
)
select rf.*
	,pf.forecast_units as previous_units
from rf
left join pf
on rf.vendor_number = pf.vendor_number
and rf.item_number = pf.item_number
and rf.forecast_date = pf.forecast_date
)