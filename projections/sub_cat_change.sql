--sub cat part for projections
--it finds the month % change 2019 - 2022 ( compare 01-2019 to 02-2019, 02-2019 to 03-2019 etc)
--the % avg between all the years are averaged discluding 2020
create or replace view projections.sub_cat_change as 
(
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
;