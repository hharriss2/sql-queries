
create or replace view power_bi.omni_ships_tracker_pbix as 
(
with s as  -- ships view
( -- need to change the dates to be by shipment and month & change the retailer id's
SELECT
	id
	,model
	,division_id
	,retailer_id
	,units
	,cbm_id
	,sales
	,sale_type
	,btrim(to_char(date_shipped::timestamp with time zone, 'Month'::text)) AS ship_month
	,btrim(to_char(date_shipped::timestamp with time zone, 'YYYY'::text)) AS ship_year
	,category_id
	,account_manager_id
from ships_schema.ships_view
)
SELECT
	s.id
	,division_id
	,retailer_id
	,units
	,cbm_id
	,sales
	,sale_type
	,cal.id as calendar_id
	,category_id
	,account_manager_id
from s
JOIN calendar cal 
ON s.ship_month = cal.month AND cal.year = s.ship_year
where 1=1
and model not like '%DISP%'
)
;
