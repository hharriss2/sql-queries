--used for the daily report query
--pack size & item type depend on the item number & vendor number
--since the lookup_stores table is by unqque prime numbers attributes, use this query to find values for pack size & item type code
create or replace view lookups.store_pack_and_type as 
(
with t1 as 
(
select 
	item_nbr
	,vendor_nbr
	,vendor_pack_quantity
	,item_type_code
	,daily
	,max(daily) over (partition by item_nbr, vendor_nbr) as latest_date
from sales_stores_auto
where 1=1
and item_type_code is not null
)
select distinct
	item_nbr
	,vendor_nbr
	,vendor_pack_quantity
	,item_type_code
from t1
where 1=1
and daily = latest_date
)