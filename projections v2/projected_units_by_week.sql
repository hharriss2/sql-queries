
create or replace view projections.projected_units_by_week as 
(
--latest version of the forecast projection
with promo as 
(--bring in the promo data in the retail history view
select
	item_id
	,model
	,group_type
	,start_date
	,end_date
	,suggested_retail
	,funding_type
	,sd.wm_date::integer as wm_start_date
	,ed.wm_date::integer as wm_end_date
from clean_data.item_grouping igroup
left join power_bi.wm_calendar_view sd
on igroup.start_date = sd.date
left join power_bi.wm_calendar_view ed
on igroup.end_date = ed.date
)
,promo_cal as -- promo calendar join 
( --assigning the wm date to each model when it's on promo
select distinct
	promo.model
	,wcv.wm_date::integer as wm_date
	,wcv.wm_week::integer as wm_week
	,wm_year
	,wm_quarter
	,max(case when date = current_date then wm_date::integer else null end) over() as current_wm_date 
	--^finds the current wm_date/week
from power_bi.wm_calendar_view wcv
join promo 
on wcv.wm_date::integer >=promo.wm_start_date  and wcv.wm_date::integer <=promo.wm_end_date
where date <=current_date + interval '27 weeks'
)
,ls as --last ships
( --bring in weighted averaeg for ships data
select
	model_name
	,cbm_id
	,model_id
	,cat
	,sub_cat
    ,wm_cal_id
	,wm_week
	,wm_year
	,wm_quarter
	,wm_date
	,total_units
	,ams_ships
    ,current_wm_week_seq
    ,most_current_total_units
from projections.last_ships_by_week
)
,scc as 
(--bring in the mom avg for sub categories
select
	sub_cat
	,wm_date
	,wm_week
	,is_wow_outlier
--setting limits of maximum 2.5 multiplier
	,case
		when coalesce(wow_average,week_over_week) >2
		then 2
		when coalesce(wow_average,week_over_week) <-1
		then -1
		else coalesce(wow_average,week_over_week)
		end as wow_average
from projections.sub_cat_lift_by_week
)
,details as 
( -- joining all the data to get the final calculation
select
	ls.model_name
	,model_id
	,cbm_id
	,ms.item_id
	,ls.cat
	,ls.sub_cat
	,ms.product_name
    ,wm_cal_id
	,ls.wm_week
	,ls.wm_year
	,ls.wm_quarter
	,ls.wm_date
	,ls.total_units
	,ls.ams_ships
    ,ls.most_current_total_units
	,scc.wow_average -- takes the mom average cumulated. 
	--if future, take the cumulation of all past months
	,scc.is_wow_outlier -- shows if the average is an outlier vs previous years' months
	,case
		when promo_cal.model is not null
		then .2
		else null
		end as promo_lift
    ,ms.division
    ,current_wm_week_seq
from ls
left join clean_data.master_ships_list ms
on ls.model_name = ms.model
left join scc
on ls.sub_cat = scc.sub_cat
and ls.wm_date = scc.wm_date
left join promo_cal
on ls.model_name = promo_cal.model and ls.wm_date = promo_cal.wm_date

)
select * 
	,(ams_ships)
		*(1 + coalesce(wow_average,0))
		*(1 + coalesce(promo_lift,0))
		as projected_units
from details
)
;
