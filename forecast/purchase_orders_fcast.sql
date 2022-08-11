--this view is to format the purchase_orders table in forecast schema
--we upload the ssr file through python code, do some clean up, and then create a view for the forecast tool
--the view assigns a unique identifier, translates days into months, and pivots a purchase order and available to sell column
create or replace view forecast.purchase_orders_fcast as (
 select --have to sum sub query to 1. sum up purchase orders and 2. create one line for purchase orders and available to sell
		dense_rank() over ( order by 
					t1.model
					,t1.ssr_month
					,t1.ssr_year
					,sum(purchase_orders)
					,sum(ats_qty)
					) as
		ssr_id
		,t1.model
		,t1.ssr_month
		,t1.ssr_year
		,sum(purchase_orders) as purchase_orders
--		,sum(purchase_orders) over (
--							 partition by model
--							 order by ssr_id) as oh_test
		,sum(ats_qty) as ats_qty
		,ssr_id as min_id
		,purchase_date + 7 as first_purchase_date 
	from
		(
	select 
--		dense_rank() over (
--		order by model
--				, date_part('month', purchase_date)::integer
--				, date_part('year', purchase_date)::integer
--				, case when transaction_type = 'PUR - Purchase Orders' then sum(units)
--					else 0 end
--				,case when transaction_type = 'AVS - Available to Sell' then sum(current_col)
--					else 0 end) as
--		ssr_id
		model
		,transaction_type
		,date_part('month', purchase_date)::integer as ssr_month
		,date_part('year', purchase_date)::integer as ssr_year
        --case statement creates columns for purchase orders and available to sell
		,case when transaction_type = 'PUR - Purchase Orders' then sum(units)
		else 0 end as purchase_orders
		,case when transaction_type = 'AVS - Available to Sell' then sum(current_col)
		else 0 end as ats_qty
	from forecast.purchase_orders
	where date_inserted::date = (select max(date_inserted::date) from forecast.purchase_orders)
	--find current ssr data
	group by 
		model
		,transaction_type
		,date_part('month', purchase_date)::integer
		,date_part('year', purchase_date)::integer
		)t1
	left join forecast.purchase_orders_min_date pom
	on t1.model = pom.model and t1.ssr_month = pom.ssr_month and t1.ssr_year = pom.ssr_year
		group by 
			t1.model
			,t1.ssr_month
			,t1.ssr_year
			,pom.ssr_id
			,pom.purchase_date
--		where model = '2000009WE'
		)
		;
