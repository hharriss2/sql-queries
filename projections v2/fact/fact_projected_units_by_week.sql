--projected units the sales team will use to make forecasts 26 weeks out
create or replace view power_bi.fact_projected_units_by_week as 
(
select
	model_id
	,cbm_id
	,id.item_id_id
	,g.group_id_id
	,d.division_id
	,c.am_id
	,pn.product_name_id
	,wcal.wm_cal_id
	,p.total_units as total_ships_units -- total units the item did for the week
	,p.ams_ships -- average monthly sales for ships. combines the last 4,12,&52 weeks for shipments to show trends
	,p.wow_average as perc_sub_cat_wow -- percent of units the subcategory did week over week
	,p.promo_lift -- if item is on promo, applies a 20% lift
	,p.projected_units -- final suggested forecast for the sales team
	,p.is_wow_outlier -- shows if the sub cat week over week percentage is a lot different from other years' weeks
	,case
		when p.total_units is null
		then projected_units
		else null
		end as projected_units_current
	,case
	when p.total_units is null
	then row_number() over (partition by model_name order by p.wm_date)
	else null
	end as wm_week_seq
    ,p.current_wm_week_seq
    ,most_current_total_units
    ,case
    	when projected_forecast_type_id = 1
    	then 0
    	when projected_forecast_type_id = 2
    	then 0
    	when projected_forecast_type_id = 3
    	then most_current_total_units
    	when projected_forecast_type_id = 4
	    	then 
	    	case
			when p.total_units is null
			then projected_units
			else null end
		else null
		end as matrix_units
	,projected_forecast_type_id
from projections.projected_units_by_week_mat_view p
left join power_bi.dim_product_names pn
on p.product_name = pn.product_name
left join power_bi.dim_wm_item_id id
on id.item_id = p.item_id
left join power_bi.wm_budget_calendar wcal
on wcal.wm_cal_id = p.wm_cal_id
left join power_bi.group_id_view g 
on p.item_id = g.tool_id
left join power_bi.divisions_view d
on p.division = d.division_name
left join category c 
on p.cat = c.category_name
left join power_bi.dim_forecast_type 
on 1=1
limit 10000
)
;