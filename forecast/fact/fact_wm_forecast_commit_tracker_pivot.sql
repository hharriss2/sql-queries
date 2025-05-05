--create for the report https://app.powerbi.com/groups/aa877baf-5525-407e-b3e6-330b8d028147/reports/a6dc6bca-8d28-4219-be2e-e17b9a36474b/46c7ac2bd9158a1b5005?experience=power-bi
--used as page 'commit pivot' so the export will export as the table looks
create or replace view power_bi.fact_wm_forecast_commit_tracker_pivot as 
(
select
	wm_date
	,wm_week
	,wm_year
	,commit_start_week
	,commit_start_year
	,item_id
	,product_name
	,commit_tag
	,commit_comments
	,is_special_buy
	,cv.unit
	,case
		when cv.unit = 'POS Units'
		then total_pos_units
		when cv.unit = 'Store Count'
		then store_count
		when cv.unit = 'UPW Forecast'
		then units_per_week_forecast
		when cv.unit= 'Units per week per store'
		then units_per_week_forecast/ nullif(store_count,0)
		else null
		end as unit_value
from power_bi.fact_wm_forecast_commit_tracker ct
join lookups.wm_forecast_commit_pivot_values  cv
on 1=1
)