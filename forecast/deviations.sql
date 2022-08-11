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
	(--TO UPDATE. convert this into another with when math is good
	select l52_units_sold.model
	,l4_units_ships
	,l12_units_ships
	,ams_units	
--	,l4_dev::numeric(10,2)
--	,l12_dev::numeric(10,2)
--	,ams_dev::numeric(10,2)
	,l4_weight
	,l12_weight
	,ams_weight
	,case when l4_dev+.15 >= ams_dev then l4_weight -.1
		when l4_dev+.1 >= l12_dev then l4_weight -.1
		when l4_dev +.15 <= ams_dev then l4_weight +.1
		when l4_dev +.1 <= l12_dev then l4_weight +.1
		else l4_weight end as l4_weight_adj_dev
	,case when l4_dev+.15 >= ams_dev then l12_weight
		when l4_dev+.1 >= l12_dev then l12_weight +.1
		when l4_dev +.1 <=l12_dev then l12_weight -.1
		else l12_weight end as l12_weight_adj_dev
	,case when l4_dev +.15<= ams_dev and l4_dev +.1 >= l12_dev then ams_weight
		when l4_dev +.15 >= ams_dev then ams_weight +.1
		when l4_dev +.15 <=ams_dev then ams_weight -.1
		else ams_weight end as ams_weight_adj_dev
	,case when l4_units_ships *2 >= ams_units then l4_weight -.1
		when l4_units_ships * 1.5 >= l12_units_ships then l4_weight -.1
		when l4_units_ships *2 <=ams_units and  l4_units_ships *1.5 <=l12_units_ships then l4_weight +.2
		when l4_units_ships * 2 <= ams_units then l4_weight +.1
		when l4_units_ships * 1.5 <= l12_units_ships then l4_weight +.1
		else l4_weight end as l4_weight_adj
	,case when l4_units_ships *2 >= ams_units then l12_weight
		when l4_units_ships *1.5 >= l12_units_ships then l12_weight +.1
		when l4_units_ships *1.5 <=l12_units_ships then l12_weight -.1
		else l12_weight end as l12_weight_adj
	,case when l4_units_ships *2 <= ams_units and l4_units_ships *1.5 >= l12_units_ships then ams_weight +.1
		when l4_units_ships *2 >= ams_units then ams_weight +.1
		when l4_units_ships *2 <=ams_units then ams_weight -.1
		else ams_weight end as ams_weight_adj
	from 
		(
		select s.model
		, (sum(units)/count(distinct to_char(date_shipped, 'YYYYMM'))::numeric(10,2))::numeric(10,2) ams_units
		,stddev(units) ams_dev
		,.2 as ams_weight
		from ships_schema.ships s
			where to_char(date_shipped, 'YYYYMM') in 
				(-- find year/month for last 12 months minus the current month 
					select distinct to_char(date_shipped, 'YYYYMM')
					from ships_schema.ships 
					where to_char(date_shipped, 'YYYYMM') != (
												select to_char(max(date_shipped),'YYYYMM') 
												from ships_schema.ships
															 )
					order by to_char(date_shipped, 'YYYYMM') desc
					limit 12
						)
			and retailer ='Walmart.com'
			group by s.model
		)l52_units_sold
	left join 
		(
		select s.model
		, (sum(units)::numeric(10,2))::numeric(10,2) l4_units_ships
		,stddev(units) l4_dev
		,.5 as l4_weight
		-- not divided because last 4 acts as true month sum
		from ships_schema.ships s
		join wm_calendar w
		on s.date_shipped = w.date
		where wm_date in (-- finds the last 4 full weeks of sales
							select distinct w.wm_date
							from ships_schema.ships s
							join wm_calendar w
							on s.date_shipped = w.date
							where wm_date != (select max(w.wm_date)-- filtes non full week
							from ships_schema.ships s join wm_calendar w on s.date_shipped = w.date)
							order by wm_date desc
							limit 4
						)
		and units >0
		and retailer ='Walmart.com'
		group by s.model
		)l4_units_sold
	on l52_units_sold.model = l4_units_sold.model
	left join 
		(
		select s.model
		, (sum(units)/3::numeric(10,2))::numeric(10,2) l12_units_ships
		,stddev(units) l12_dev
		,.3 as l12_weight
		-- divided by 3 to show an month average
		from ships_schema.ships s
		join wm_calendar w
		on s.date_shipped = w.date
		where wm_date in (-- finds the last 12 full weeks of sales
							select distinct w.wm_date
							from ships_schema.ships s
							join wm_calendar w
							on s.date_shipped = w.date
							where wm_date != (select max(w.wm_date)-- filtes non full week
							from ships_schema.ships s join wm_calendar w on s.date_shipped = w.date)
							order by wm_date desc
							limit 12
						)
		and units >0
		and retailer = 'Walmart.com'
		group by s.model
		)l12_units_sold
	on l12_units_sold.model = l52_units_sold.model
	where ams_units >0 

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