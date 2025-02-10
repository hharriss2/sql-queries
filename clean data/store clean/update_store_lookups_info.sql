--unique and most recent vendor stock nummber, item description, and unit retail for the store sales
insert into pos_reporting.lookup_stores (prime_item_num, vendor_stock_number, prime_item_desc,unit_retail)
--START SELECT QUERY
    -- findS unique vendor #, item description, & unit retail
with t1 as 
(
select
	prime_item_nbr
	,vendor_stk_nbr
	,prime_item_desc
	,unit_retail
	,daily
	,max(daily) over (partition by prime_item_nbr) latest_day
from sales_stores_auto
where vendor_stk_nbr is not null
)
,t2 as 
(
select distinct
	prime_item_nbr
	,max(vendor_stk_nbr) as vendor_stk_nbr
	,max(prime_item_desc) as prime_item_desc
	,max(unit_retail) as unit_retail
from t1
where 1=1
and daily = latest_day
group by prime_item_nbr
)
select prime_item_nbr::bigint
	,vendor_stk_nbr
	,prime_item_desc
	,unit_retail::numeric(10,2)
from t2
--END SELECT QUERY
--Finish with upserting
on conflict(prime_item_num)
do update set 
vendor_stock_number = excluded.vendor_stock_number
, prime_item_desc = excluded.prime_item_desc
,unit_retail = excluded.unit_retail
;
