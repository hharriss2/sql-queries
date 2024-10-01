--finds the every day retail
--most popular AUR for by item, by year
create or replace view forecast.edr_year as 
(
with rp as -- retail price
( -- find each retail price rounded to the nearest 10 dollars
select
	item_id
	,date_part('year',sale_date) as sale_year
	,(((sales/nullif(units,0)) * .1)::numeric(10,0))* 10 as retail_price
from retail_linK_pos
)
,rpc as --retail price count
(--finding which retail occurs the most out of all the retails
select 
	item_id
	,sale_year
	,retail_price
	,count(item_id) as num_times_at_retail
from rp
where 1=1
and retail_price is not null
group by item_id
	,sale_year
	,retail_price
)
,details as 
(
select
	item_id
	,sale_year
	,retail_price
	,num_times_at_retail
	,row_number() over (partition by item_id, sale_year order by num_times_at_retail desc, retail_price desc) 
	as num_times_retail_seq  -- orders incrament by 1, takes the highest retail if multiple counts are the same
from rpc
)

select item_id
	,sale_year
	,retail_price
from details
where 1=1
and num_times_retail_seq = 1
)
;
