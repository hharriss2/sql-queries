create or replace view forecast.purchase_orders_min_date as (
/*Finds the first date a purchase order takes place*/
/*1. Find where a purchase order has units for an item*/
/*2. Make a subquery out of it, find the min ID out of that, group by month and year to connect to other forecast table*/

select model
	,ssr_month
	,ssr_year
	,min(ssr_id) as ssr_id
	,min(purchase_date) as purchase_date
	--2. subquery to find the min id for purchase order date. Purchase order can happen multiple times a month
from
(--finds the id from raw data where there is a purchase order
	select 
		model
		,purchase_date
		,date_part('month', purchase_date)::integer as ssr_month
		,date_part('year', purchase_date)::integer as ssr_year
		,units
		,current_col
        --1. find min id where units are greater than 0
		,case when units >0 then min(id) else null end as ssr_id
	from forecast.purchase_orders
	where 1=1
	and date_inserted::date = (select max(date_inserted::date) from forecast.purchase_orders)
	and transaction_type = 'PUR - Purchase Orders'
	group by 
		model
		,purchase_date
		,date_part('month', purchase_date)::integer
		,date_part('year', purchase_date)::integer
		,units
		,current_col
	)t1

	where ssr_id is not null
	group by 
	model
	,ssr_month
	,ssr_year
--	,purchase_date
    --3. exlude any purchase orders with nulls. we only want the first instance of a purchase order
)
;