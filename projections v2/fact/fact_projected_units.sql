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
	,rt.retail_price -- the retail price an item does POS sales at for the week
	,rt.total_units as total_sales_units -- total units sold on the specific week 
	,rt.is_retail_spike -- does the retail change by $5 from previous week 
	,rt.perc_wow as perc_retail_wow -- percent in units sold from last week 
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
	,sum(case
		when p.wm_year = '2025'
		then p.total_units
		else null
		end) over (partition by model_name, p.wm_date) 
		as total_units_2024
	,sum(case
		when p.wm_year = '2024'
		then p.total_units
		else null
		end) over (partition by model_name, p.wm_date) 
		as total_units_2023
	,sum(case
		when p.wm_year = '2023'
		then p.total_units
		else null
		end) over (partition by model_name, p.wm_date) 
		as total_units_2022
	,sum(case
		when p.wm_year = '2022'
		then p.total_units
		else null
		end) over (partition by model_name, p.wm_date) 
		as total_units_2021
	,sum(case
		when p.wm_year = '2021'
		then p.total_units
		else null
		end) over (partition by model_name, p.wm_date) 
		as total_units_2020
	,sum(case
		when p.wm_year = '2020'
		then p.total_units
		else null
		end) over (partition by model_name) 
		as total_units_2019
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
	,sum(case
		when p.wm_year = '2026'
		then p.total_units
		else null
		end) over (partition by model_name, p.wm_date) 
		as total_units_2025
from projections.projected_units_by_week_mat_view p
left join projections.retail_trend rt
on p.item_id = rt.item_id
and p.wm_cal_id = rt.wm_cal_id
left join dim_sources.dim_product_names pn
on p.product_name = pn.product_name
left join dim_sources.dim_wm_item_id id
on id.item_id = p.item_id
left join power_bi.wm_budget_calendar wcal
on wcal.wm_cal_id = p.wm_cal_id
left join power_bi.group_id_view g 
on p.item_id = g.tool_id
left join power_bi.divisions_view d
on p.division = d.division_name
left join category c 
on p.cat = c.category_name
left join dim_sources.dim_forecast_type 
on 1=1
left join forecast.forecast_dhp fdhp
on p.model_name = fdhp.model

)
;