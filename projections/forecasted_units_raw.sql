--gets all the calculations for forecast projections
--month ratio is used to calculate final forecasted_units view
create or replace view projections.forecasted_units_raw as
(
with retail as 
(-- projection_aur inserts into retail_projection tbl. 
--done for speed
--last of calculations are handled here
	select 
	item_id
	,projected_aur
	,sale_month
	,case 
		when date_part('month', now()) = sale_month
		then 40 --if current month, use current aur
		else projected_aur -- if not, use the projected aur
		end as aur
	,case 
		when cred_weight * ams_over_ams >= .1 
			then .1 -- if ams % greater than 10%, cap at 10%
		when cred_weight * ams_over_ams <=-.1
			then -.1 -- if ams% is less than -10%, cap at -10%
		else cred_weight * ams_over_ams
		end as aur_ams_over_ams 
	--retail_id below lets us order items by the current month then the following.
	,dense_rank() over (order by item_id,CASE 
     WHEN sale_month = date_part('month', now())
     THEN 0
      when sale_month < date_part('month',now())
      then sale_month +12
      else 1
     END) as retail_id
	from projections.retail_projection_tbl
)
,deviation as 
( --deviation is taken from a view
	select * 
	,coalesce(
		(l4_units_ships * l4_weight_adj) + (l12_units_ships * l12_weight_adj) + (ams_units * ams_weight_adj )
		,(l4_units_ships *l4_weight) + (l12_units_ships * l12_weight) + (ams_units * ams_weight)
		,(l12_units_ships * .7) + (ams_units * .3)
		,0
		
		) as ams_ships
	from projections.deviation
)
,
sub_cat_change as
( --also taken from a view
	select sub_cat
		,month_num
		,case when mom_average >.1 then .1
		when mom_average <-.1 then -.1
		else mom_average
		end as mom_average
	from projections.sub_cat_change
)
,promo as 
( -- finds when an item is/was on promo. 
 select distinct model,item_id, date_part('month',forecast_date) as promo_month, .15 as promo_ratio
 from pos_reporting.promo_range2
)
select retail_id as fcast_units_id
,retail.item_id
,deviation.model
,sub_cat_change.sub_cat
,deviation.ams_ships
,retail.aur
,retail.sale_month as month_num
,retail.aur_ams_over_ams
,mom_average -- month over month average
,coalesce(promo.promo_ratio, 0) as promo_ratio
-- way for calculations. takes % overs and multiplies them
, (deviation.ams_ships) 
	* (1+ coalesce(aur_ams_over_ams,0)) 
	* (1 + coalesce(mom_average,0)) 
	* (1 + coalesce(promo_ratio,0))  as forecasted_units
--new way. adds %'s to multiply against ams
--, (deviation.ams_ships) 
--	* (
--	1
--	+coalesce(aur_ams_over_ams,0)
--	+coalesce(mom_average,0)
--	+coalesce(promo_ratio,0)
--	) as forecasted_units_alt
from retail
join clean_data.master_com_list ml
	on retail.item_id = ml.item_id
join deviation 
	on deviation.model = ml.model
join cat_by_model cbm
	on deviation.model =  cbm.model
left join sub_cat_change 
	on sub_cat_change.sub_cat = cbm.sub_cat
	and sub_cat_change.month_num::integer = retail.sale_month
left join promo
	on promo.item_id = retail.item_id
	and promo.promo_month = retail.sale_month
order by retail_id
)
;