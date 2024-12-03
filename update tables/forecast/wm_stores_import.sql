--used in pandas file forecast_stores_import.py
--file is uploaded to dapl raw, then this is used to insert into the wm stores import table
insert into forecast.wm_stores_import 
(prime_item_number
,item_description
,warehouse_number
,wm_date
,unconstrained_units
,constrained_units
,ship_date
)
with sic as --store import clean
(-- raw data from pandas import needs a few things for cleaning
--renaming columns
--grouping wm dates together
--distinguishing the unconstrained, constrained units, and shipping dates
select
	si."BI-Prime Item Nbr" as prime_item_number
	,si."BI-Item Desc 1" as item_description
	,si."BI-Whse Nbr" as warehouse_number -- rename
	,case -- creates a walmart date column
		when si.forecast_date like 'UOP-%' or si.forecast_date like 'COP-%'
		then right(si.forecast_date,length(si.forecast_date) - 4)::integer
		when si.forecast_date like 'SDFP-%'
		then right(si.forecast_date,length(si.forecast_date) - 5)::integer
		else null
		end as wm_date
	,case -- creates units for unconstrained column
		when si.forecast_date like 'UOP-%'
		then units::integer
		else null
		end as unconstrained_units
	,case -- creates units for constrained column
		when si.forecast_date like 'COP-%'
		then units::integer
		else null
		end as constrained_units
	,case -- creates a date forecast
		when si.forecast_date like 'SDFP-%'
		then units::date
		else null
		end as ship_date
from dapl_raw.forecast_stores_import si
)
,details as 
( -- grouping the unit and dates on the wm date level.
select 
	prime_item_number
	,item_description
	,warehouse_number
	,wm_date
	,max(unconstrained_units) as unconstrained_units -- maxing these will give us the number all on one wm date colum
	,max(constrained_units) as constrained_units
	,max(ship_date) as ship_date
from sic
group by prime_item_number
	,item_description
	,warehouse_number
	,wm_date
)
select
prime_item_number
,item_description
,warehouse_number
,wm_date
,unconstrained_units
,constrained_units
,ship_date
from details
where unconstrained_units + constrained_units >0
order by prime_item_number, warehouse_number, wm_date
;