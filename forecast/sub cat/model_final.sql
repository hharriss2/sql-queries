create or replace view forecast.model_final as (
with model_final as 
	(
--START SUB CAT FINAL
	select
		model
		,dense_rank() over (partition by model order by  month_num) as model_id
		,month_num
		,month_rank
		,total_units
		,first_value(month_rank) over (partition by model order by case when total_units is not null then month_rank else 9999 end) as first_rank
		,first_value(month_rank) over (partition by model order by case when total_units is not null then month_rank2 else 9999 end) as last_rank
		,first_value(total_units) over (partition by model order by case when total_units is not null then month_rank else 9999 end) as first_units
		,first_value(total_units) over (partition by model order by case when total_units is not null then month_rank2 else 9999 end ) as last_units
		,lag(total_units) over (partition by model order by month_num) prev_month_units
		,case when lag(total_units) over (partition by model order by month_num) is not null then 1 else 0 end 
		+case when lead(total_units) over (partition by model order by month_num) is not null then 1 else 0 end as count_case
		--counted for average later on in total units
		,lead(total_units) over (partition by model order by month_num) as post_month_units
	from
		( 
		with model_sales as 
			--finds a date for every sub cat, assigns averages of month for any missing month
			--purpose: find months that are missing sales for each year, divide total units by that number and apply it 
			--theres only 2 or 3 that meet this scenario. Won't affect the sub cat ratio that hard
			(
		--START SUB CAT SALES	
			with sc1 as
				(
				select model
				,month_num
				,year_num
				,total_units
				from forecast.model_sales
				)
			,sc2 as 
				(-- average units by month.
				select model
				,month_num
				,avg(total_units::integer) as total_units
				from forecast.model_sales
				group by model
				,month_num
				)
			--if total units exists, take them. if not, use the average
			select sc1.model
				,sc1.month_num
				,sc1.year_num
				,case when sc1.month_num in (1,2,3) then 1
				when sc1.month_num in (4,5,6) then 2
				when sc1.month_num in (7,8,9) then 3
				when sc1.month_num in (10,11,12) then 4
				end as units_qrtly
					,coalesce(sc1.total_units::integer, sc2.total_units::integer) as total_units
				from sc1
				join sc2
			on sc1.model = sc2.model and sc1.month_num = sc2.month_num
		--END SUB CAT SALES
			)
		select model
			,month_num
			,sum(total_units) as total_units
			,case when sum(total_units) is not null then dense_rank() over (partition by model order by month_num)
			else null end as month_rank
			,case when sum(total_units) is not null then dense_rank() over (partition by model order by month_num desc)
			else null end as month_rank2
		from model_sales
		group by model
			,month_num
		)t1	
--END SUB CAT FINAL
	)
select 
model
,month_num
,coalesce(total_units,
	case 
		when month_num <first_rank 
	then first_units
	when month_num > last_rank then last_units end
	,(prev_month_units + post_month_units )/ (count_case)
	) as total_units
from model_final
order by model, month_num
);