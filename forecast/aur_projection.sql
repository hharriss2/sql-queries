create or replace view forecast.aur_projection as (
with 
retail_price as 
	(--EDR Retail and Curent Price
	select
		rp.item_id
		,rp.price_retail as current_price
		,edr.retail_price as edr_price
		,edr.sale_year
	from
		(
		--current retail prices	
		select
		item_id
		,price_retail
		,date_part('month',now()::date) as current_month
		from power_bi.retail_price
		) rp
	join 
		forecast.edr_year edr
	on rp.item_id= edr.item_id
	where 1=1
	and edr.sale_year = date_part('year',now())
--	and rp.item_id = '332042587'
 	)
,
aur_change as 
	(
/*Start aur_change*/
select 	
	item_id
	,sale_month	
	,avg(aur_trend)::numeric(10,2) as aur_trend
from
	(
	--START aur_trends
		--Item ID's EDR % change for Aur of each years month
		--Subquery here to avg months trends
		select
			month_aur.item_id
			,aur_id
			,month_year
			,month_aur.sale_year
			,sale_month
			,((aur_month-retail_price)/(retail_price))::numeric(10,2) as aur_trend
	--		,avg(((aur_month-aur_last_month)/(aur_last_month)))::numeric(10,2)
		from
			(
			--start month_aur
				--finds the aur for the item by month and year
				--adds aur_last_month as a column to get previous aur
				select  
					dense_rank() over (partition by item_id order by month_year desc)
					as aur_id
					--helps visualize whats going on with aur_last_month
					,item_id
					,month_year
					,sale_year
					,sale_month
					, sum(sales)/sum(units) as aur_month
		--			,coalesce(lead(sum(sales)/sum(units)) over(partition by item_id order by month_year desc),sum(sales)/sum(units))
		--				as aur_last_month
					--moves previous month aur next to the next month
					--use this to calculate % change later
					--if first_month = 1, aur_month = aur_last month. done to 0 out change for beginning of month_year
					,dense_rank() over(partition by item_id order by month_year) as first_month
					--filter in above select statement. start % change as 0 for the year
				from 
					(
					--start r
						--finds sales and units for each item id by year/month
					select
					item_id
					,to_char(sale_date,'YYYY-MM') as month_year 
					--formatting month_year for aur_last_month sorting above. formatted for the 'order by' 
					,date_part('year',sale_date) as sale_year
					--extract year for partition
					,date_part('month',sale_date) as sale_month
					,sales
					,units
				  	from retail_link_pos
				  	where units >0
				  	and sales >0
				  	--omits returns. cannot divide by 0's 
				  	--end r
					  ) r
				where 1=1
		--		and item_id = '10153765'
				group by item_id
						,month_year
						,sale_year
						,sale_month
			--end month_aur
			) month_aur
		join forecast.edr_year edr
		on month_aur.item_id = edr.item_id
		and month_aur.sale_year = edr.sale_year
		where 1=1
--		and month_aur.item_id = '332042587'
		and abs(((aur_month-retail_price)/(retail_price))::numeric(10,2)) <.1
		and retail_price >0
	--END aur_trend
	) aur_trends
	group by 
		item_id
		,sale_month	
/*End aur_change*/
	)
select retail_price.item_id
--	,current_price
--	,edr_price
	,case when date_part('month', now()) = sale_month
		then current_price
		else (edr_price * (1 + (aur_trend)))::numeric(10,2)
		end as projected_aur
--		sum these to line them on the same row
	,sale_month
--	,aur_trend
from retail_price
join aur_change
on retail_price.item_id = aur_change.item_id
)
;


