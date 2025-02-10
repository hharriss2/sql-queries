--sales stores auto data cleaned up similar to pos_reporting.retail_sales
--only includes sales info we'd want to have in the wm_stores_pos (power bi sales)
create or replace view pos_reporting.store_sales as 
(
with vn as --valid item numbers
( -- a list of the valid item numbers we want to include from sales stores auto data
SELECT item_num
FROM pos_reporting.lookup_valid_item_nums
)
,ssa as 
( -- data we want to include in sales stores auto 
SELECT 
	s.id
	,coalesce(current_item_num::bigint, prime_item_nbr::bigint) as prime_item_nbr
	,coalesce(ls.prime_item_desc, s.prime_item_desc) as prime_item_desc
	,item_nbr
	,item_flags
	,item_desc_1
	,upc
	,vendor_stk_nbr
	,vendor_name
	,vendor_nbr
	,vendor_sequence_nbr
	,wm_week
	,daily
	,s.unit_retail
	,avg_retail
	,pos_qty
	,pos_sales
	,curr_repl_instock
	,case -- shows if the item number is different than the original
		when current_item_num is not null and current_item_num != s.prime_item_nbr
		then 1
		else 0 
		end as is_overwriten_item_nbr
from sales_stores_auto s
left join pos_reporting.lookup_stores ls
on s.prime_item_nbr::bigint = ls.prime_item_num
where fineline_description <> 'DOTCOM ONLY'::text -- do not want .com data feeding into stores pos
and prime_item_nbr::bigint in (select item_num from vn) -- only want what's on the valid item number list
)
,details as 
(
select 
	ssa.id
	,prime_item_nbr
	,prime_item_desc
	,ssa.item_nbr
	,ssa.item_flags
	,ssa.item_desc_1
	,ssa.upc
	,ssa.vendor_stk_nbr
	,ssa.vendor_name
	,ssa.vendor_nbr
	,ssa.vendor_sequence_nbr
	,ssa.wm_week
	,ssa.daily
	,ssa.unit_retail
	,ssa.avg_retail
	,ssa.pos_qty
	,ssa.pos_sales
	,ssa.curr_repl_instock
	,is_overwriten_item_nbr
	,ssa.prime_item_nbr as original_item_num
from ssa
)
select * 
from details
)
;
