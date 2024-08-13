--used to join items on the pos & shipping table
create or replace view power_bi.fact_item_gouping as 
(
select
	ig.item_group_id
	,i.item_id_id
	,g.group_id_id
	,m.model_id
	,cbm.cbm_id
	,ac.account_manager_id
	,sd.wmcal_id as start_date_id
	,ed.wmcal_id as end_date_id
	,funding_amount
	,suggested_retail
	,division_id
	,gt.group_type_id
	,ig.start_date
	,ig.end_date
	,sd.wm_date as wm_start_date
	,ed.wm_date as wm_end_date
from clean_data.item_grouping ig
left join power_bi.dim_wm_item_id i
on ig.item_id = i.item_id
left join power_bi.dim_models m
on ig.model = m.model_name
left join power_bi.wm_calendar_view sd -- start date
on ig.start_date = sd.date
left join power_bi.wm_calendar_view ed -- end date
on ig.end_date = ed.date
left join cat_by_model cbm 
on ig.model = cbm.model
left join account_manager_cat ac
on cbm.cat = ac.category_name
left join clean_data.master_com_list mcl
on ig.item_id = mcl.item_id
left join divisions d 
on mcl.division = d.division_name
left join power_bi.group_id_view g
on ig.item_id = g.tool_id
left join power_bi.dim_group_type gt
on ig.group_type = gt.group_type
)
;
