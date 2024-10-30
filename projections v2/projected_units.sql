create or replace view projections.projected_units as 
(
--latest version of the forecast projection
with ls as --last ships
( --bring in weighted averaeg for ships data
select
	model_name
	,cat
	,sub_cat
	,month_num
	,cal_month
	,total_units
	,ams_ships
	,current_month_seq
	,most_current_total_units
from projections.last_ships
)
,scc as 
(--bring in the mom avg for sub categories
select
	sub_cat
	,cal_month
	,month_num
	,is_mom_outlier
--setting limits of maximum 2.5 multiplier
	,case
		when coalesce(mom_average,month_over_month) >2
		then 2
		when coalesce(mom_average,month_over_month) <-2
		then -2
		else coalesce(mom_average,month_over_month)
		end as mom_average
from projections.sub_cat_lift
)
,details as 
( -- joining all the data to get the final calculation
select
	ls.model_name
	,ms.item_id
	,ls.cat
	,ls.sub_cat
	,ms.product_name
	,ls.cal_month
	,ls.current_month_seq
	,ls.total_units
	,ls.most_current_total_units
	,ls.ams_ships
	,scc.mom_average -- takes the mom average cumulated. 
	--if future, take the cumulation of all past months
	,scc.is_mom_outlier -- shows if the average is an outlier vs previous years' months
from ls
left join clean_data.master_ships_list ms
on ls.model_name = ms.model
left join scc
on ls.sub_cat = scc.sub_cat
and ls.cal_month = scc.cal_month
where 1=1

)
select * 
	,(ams_ships) *(1 + coalesce(mom_average,0))
		as projected_units
from details
)
;
