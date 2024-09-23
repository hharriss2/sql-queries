 -- projecting units for each month on an item
--applies monthly ships, sub category, & promotional lifts to the avg monthly units shipped
create or replace view projections.projected_lift as 
(
with cal as
( -- bringing in calendar dates
select date as cal_date
from wm_calendar 
)
,mn as --month number
( -- creates a row for months 1-12
select distinct date_part('month',cal_date) as month_num
from cal
)
,promo as 
( -- bring in promo data. need to turn start&end date columns into row format
select model
	,start_date
	,coalesce(end_date, start_date + interval '1 year')::date as end_date
	--^ if end date is null, advance the promo out a year
from clean_data.item_grouping
)
,pb as --promo bool
( -- if this record exists, apply a promo lift
--finding model and month date as a row. converting month-year to just a month
select distinct 
	model
	,date_part('month',cal.cal_date) as promo_month -- converting the dates between start & end date into a month
	,.05 as promo_ratio -- % increase for the model during the month it's on promo
from promo
join cal 
on promo.start_date <= cal.cal_date and promo.end_date >=cal.cal_date
where 1=1
and start_date >= current_date - interval '1 year'
--^filtering for promos done in the last year
)
,dev as --deviation
( -- bring in the weighted average ships data
	--no good reason it's called deviation. might rename later
select * 
--using adjusted weight formula, then regular weight formula, then last 12 & ams of others aren't valid
,coalesce(
	(l4_units_ships * l4_weight_adj) + (l12_units_ships * l12_weight_adj) + (ams_units * ams_weight_adj )
	,(l4_units_ships *l4_weight) + (l12_units_ships * l12_weight) + (ams_units * ams_weight)
	,(l12_units_ships * .7) + (ams_units * .3)
	,0
	
	) as ams_ships
from projections.deviation
)
,scc as --sub cat change
( -- bring in the mom avg for sub categories
select
	sub_cat
	,month_num::integer as month_num
	,mom_average
	--other columns available for applying mom avg
--	,mom_average_original
--	,stddev_mom
from projections.sub_cat_change
)
select
	dev.model
	,ms.item_id
	,mn.month_num 
	,cbm.sub_cat
	,dev.ams_ships
	,scc.mom_average
	,pb.promo_ratio
	, (dev.ams_ships) 
		* (1 + coalesce(scc.mom_average,0)) 
		* (1 + coalesce(pb.promo_ratio,0))  
	as projected_units
from dev
join mn
on 1=1
left join clean_data.master_ships_list ms
on dev.model = ms.model
left join cat_by_model cbm
on dev.model = cbm.model
left join scc 
on cbm.sub_cat = scc.sub_cat and scc.month_num = mn.month_num
left join pb
on dev.model = pb.model and mn.month_num = pb.promo_month
where 1=1
--1005222COM - test case model bc it has promo for 7 & 8 months, but has low AMS
--3133098 -model that does a lot of volume
)
;