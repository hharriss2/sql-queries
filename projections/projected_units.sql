
--final projection for units over 12 months.
--finds the model by month projected lift, then applies a ratio for the % of total projected the model will sale for the month
create or replace view projections.projected_units as 
(
with pu as -- projection for units
( --base projection. finds ams then applies the lifts
select * 
from projections.projected_lift
--where model = '1004846COM'
order by model, month_num
)
,mr as --model ratio
(-- finds the % of units we should allocate to the total projection
select
	model
	,month_num
	,total_units -- total units from the month avg
	,cast -- total the units over their months, then find the % to apply to projected units
	(total_units
	/sum(total_units) over (partition by model) 
	as numeric(10,2)
	)as unit_ratio
	,total_units_2019
    ,total_units_2020
    ,total_units_2021
    ,total_units_2022
    ,total_units_2023
    ,total_units_2024
--	,total_units_original -- total units from month avg before the edit
--	,stddev_units -- shows the deviation for the total units from month avg
from projections.model_unit_average
)
select
	pu.model
	,pu.item_id
	,pu.month_num
	,pu.sub_cat --sub cat affects the mom_average lift
	,pu.ams_ships
	,pu.mom_average as sub_cat_lift -- % applied to projected units 
	,pu.promo_ratio -- % applied to projected units
	,pu.projected_units --ams_ships * (1+ sub cat lift) * (1 + promo lift)
	,mr.total_units as avg_monthly_units--month avg units for the ratio portion
	,mr.unit_ratio -- sum of total units by model
	,coalesce( -- finds sum(projected_units) * unit ratio. distributes totaled projectections
		sum(projected_units) over (partition by pu.model) * unit_ratio
		,ams_ships -- if no ratio %, then use the ams_ships
		) as final_projected_units
    ,pu.projected_units - mr.total_units as projected_vs_avg_monthly
        --gives insite to how far off the AMS is. sometimes AMS includes a bunch of 0's
        --14678BKH1 shows ~800 ams, but it's more like 5k ams.
    /*show the actual units shipped for each month*/
    ,total_units_2019
    ,total_units_2020
    ,total_units_2021
    ,total_units_2022
    ,total_units_2023
    ,total_units_2024
from pu
left join mr
on pu.model = mr.model
and pu.month_num = mr.month_num
)
;
