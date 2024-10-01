--create or replace view forecast.forecast_units as (
with retail as 
	(	
		select distinct 
			r.item_id
			,r.price_retail
			,aur_compare.aur
			, aur_compare.aur_ams
			,cred_weight
			,case when avg_ams >0
			then (aur_ams- avg_ams) / avg_ams
			else 1
			end as ams_over_ams
		from power_bi.retail_price r
		join 
			(--AUR Compare. 	
			select distinct 
			item_id
			,aur
			,units
			,((units/weeks_sold_at_retail) *4)::numeric(10,2) as aur_ams
			,weeks_sold_at_retail
			,dense_rank() over (partition by item_id order by (units/weeks_sold_at_retail)*4 desc) as aur_ranking
			,row_id
			,case 
					when row_id =1 then .9
					when row_id = 2 then .5
					when row_id = 3 then .3
					else .1
					end as cred_weight
			from
				(--SQ2. Rounds AUR to 10, sums weeks sold at retail, gives it a ranking from highest weeks sold to lowest
				select item_id
					, ((aur * .1 )::numeric(10,0)) * 10 as aur
					, sum(sum_units) units
					,sum(wm_week_count) as weeks_sold_at_retail
					,dense_rank() over(partition by item_id order by sum(wm_week_count) desc ) as row_id
				from
					(--SQ1.  finds aur& sum units by item id and week.
						select item_id
							,wm_week
							,(sum(sales)/sum(units))::numeric(10,0) as aur
							,sum(units) as sum_units
							,count(distinct wm_week) as wm_week_count
						from retail_link_pos
						where units >0
			--			and item_id = '38797912'
						group by item_id,wm_week
					--END SQ1
					)aur_sum
				--group aur's together to find sum of units for that Item's aur
				group by 
					item_id
					,((aur * .1 )::numeric(10,0))
				--END SQ2
				) t2
			where 1=1
			--only use this logic when finding BEST retails
			--take into account credibility by looking at weeks sold. 
			--trusting data that sells at an aur for multiple weeks
--			and case when weeks_sold_at_retail <=2 then row_id =1
--			when weeks_sold_at_retail <=10 then row_id <=2
--			else row_id <=3
--			end
--			and weeks_sold_at_retail >0		
			) aur_compare
		on r.item_id = aur_compare.item_id
		left join	
			(
			select sum(units)/count(distinct wm_week) as avg_ams, item_id
			from retail_link_pos
			where units >0
			group by item_id
			) t3
		on r.item_id = t3.item_id
		where 1=1
		and ((price_retail *.1)::numeric(10,0)) * 10 = aur	
--		and r.item_id = '738135322'

	)
,
sub_cat_change as 
	(--average out month over month change. disclude 2020 data
	select sub_cat
		,right(year_month,2) as month_num
		,avg(month_over_month)::numeric(10,2) as mom_average
	from
		(--SQ2. find month over month change
		--WARNING FIX LAG AND LEAD.month over month leaks into other sub cats at the end
		select sub_cat
			,year_month
			,sum_units
			,lag(sum_units,1) over (order by sub_cat_id) as lead_sum_units
			, lag(sum_units,1) over (order by sub_cat_id) + sum_units as totald_units
			, ((sum_units)- (lag(sum_units,1) over (order by sub_cat_id)))/ (lag(sum_units,1) over (order by sub_cat_id))::numeric(10,2) as month_over_month
		from
		(--SQ1. Find sum of units for sub cat by month/year
			select dense_rank() over (order by sub_cat, to_char(r.sale_date, 'YYYY-MM')) as sub_cat_id
			--assign dense rank to order for lead calculation later
				,sub_cat
				,to_char(r.sale_date, 'YYYY-MM') as year_month
				--grouping by year month
				, sum(units) as sum_units
			from retail_link_pos r
			join clean_data.master_com_list ml
			on r.item_id = ml.item_id
			left join cat_by_model cbm
			on cbm.model = ml.model
			where units >0
			and sale_date not between '2020-01-01' and '2020-12-31'
		--	and sub_cat like '%Baby Mat%'
			group by sub_cat
				,to_char(r.sale_date, 'YYYY-MM')
		--END SQ1
		) t1
	--END SQ2	
	)t2
	group by sub_cat,right(year_month,2)
	)
,deviation as 
	(
	select * 
	from projections.deviation
	)
select retail.item_id
	,deviation.model
	,sub_cat_change.sub_cat
	,retail.aur
	,retail.aur_ams
	,(l4_units_ships * l4_weight_adj) + (l12_units_ships * l12_weight_adj) + (ams_weight_adj * ams_units) as ams_ships
	,mom_average as month_over_month_perc
	,(cred_weight * ams_over_ams)::numeric(10,2) as ams_perc -- takes into account credibility of aur ams
	,((l4_units_ships * l4_weight_adj) + (l12_units_ships * l12_weight_adj) + (ams_weight_adj * ams_units)) *(1+((((cred_weight * ams_over_ams)::numeric(10,2)) + mom_average))) as forecasted_units
	,tool_id_id
	,date_part('month',now()::date) as current_month_num
from retail
join clean_data.master_com_list ml
on retail.item_id = ml.item_id
join deviation on deviation.model = ml.model
join cat_by_model cbm
on deviation.model =  cbm.model
join sub_cat_change on sub_cat_change.sub_cat = cbm.sub_cat
left join power_bi.tool_id_view tv
on retail.item_id::text = tv.tool_id
where sub_cat_change.month_num = to_char(now()::date,'mm')
--)

;