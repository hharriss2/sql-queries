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
	id
	,prime_item_nbr::bigint as prime_item_nbr
	,prime_item_desc
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
	,unit_retail
	,avg_retail
	,pos_qty
	,pos_sales
	,curr_repl_instock
from sales_stores_auto
where fineline_description <> 'DOTCOM ONLY'::text -- do not want .com data feeding into stores pos
and prime_item_nbr::bigint in (select item_num from vn) -- only want what's on the valid item number list
)
,smax_s1 as  --sales max step 1
(-- find the max relation for a item description to an item number. 
SELECT DISTINCT 
	prime_item_nbr
	,prime_item_desc
    ,max(daily) AS last_sale_date
    ,max(daily) over (partition by prime_item_nbr) as last_sale_date_item_nbr
FROM ssa
GROUP BY prime_item_desc,prime_item_nbr,daily
order by prime_item_desc, last_sale_date desc
)
,smax_s2 as --sales max step 2
(-- find items with the same name but different item nums
	--compare the last date item was sold to the most recent sale date. if it's greater than 6 months, we'll disclude it from the list
select 
	prime_item_nbr
	,prime_item_desc
	,last_sale_date
	,lag(last_sale_date) over (partition by prime_item_desc order by last_sale_date desc) as prev_last_sale_date
from smax_s1
where last_sale_date_item_nbr = last_sale_date
)
,smax_s3 as 
(
select 
	prime_item_nbr
	,prime_item_desc
	,last_sale_date
	,prev_last_sale_date
	,cast((prev_last_sale_date - last_sale_date) /30 as integer) as months_from_last_item_desc
	,case -- flag to find items that don't have previous date or previous date is less than 6 months apart from other item. 
		when prev_last_sale_date is null then 0
		when cast((prev_last_sale_date - last_sale_date) /30 as integer) <4
		then 0
		else 1
		end as is_similar_sale_date
	,count(prime_item_desc) over (partition by prime_item_desc) as count_item_desc
	,row_number() over (partition by prime_item_nbr) as item_nbr_seq
from smax_s2
)
,smax as 
(-- final logic to finding the most current item number assigned to the item
select s3.prime_item_nbr
	,s3.prime_item_desc
	,s3.last_sale_date
	,is_similar_sale_date
--	,months_from_last_item_desc -- finding # of months between item descriptions
--	,lag(prime_item_nbr) over (partition by prime_item_desc order by last_sale_date desc) as similar_item_num
	,count_item_desc --total amount of item nums with the same description
	,case --  determine if the item number belongs to the current item description
		when is_similar_sale_date =0 -- if the sale dates are not similar, move onto next condition
		and count_item_desc - sum(is_similar_sale_date) over (partition by prime_item_desc) =1
		--^ There can only be 1 item without a similar date in the total # of items with the same description
		then 1 -- 1 = the item number that will overwrite 
		else 0 -- 0 means item(s) will not be overwriting other items
		end as is_overwriting_item_num
	,item_nbr_seq
from smax_s3 s3
where 1=1
and item_nbr_seq =1

)
,mcl as --master list
( -- only bringing in item numbers for the dataset
SELECT mcl.item_id,
	model,
	division,
	product_name,
	is_scrape_product_name,
	store_item_id,
	retailer_type_id AS retail_type_id,
	current_item_id AS current_item_num
from clean_data.master_com_list mcl
where retailer_type_id = 1--store type id 
)

,details as 
(
select 
	ssa.id
	,coalesce(mcl.current_item_num,smax2.prime_item_nbr, ssa.prime_item_nbr) as prime_item_nbr
	,smax1.prime_item_desc as prime_item_desc
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
	,case -- looks to see if the item number was taken from the smax table. 
		when mcl.current_item_num is not null
		then 1 -- existing record in this field means the item number has been overwritten 
		when smax2.prime_item_nbr is null -- if null, no overwriting 
		then 0
		when ssa.prime_item_nbr != smax2.prime_item_nbr -- if the original item number and prime item number dont match, it's overwritten
		then 1
		else 0
	end as is_overwriten_item_nbr
	,ssa.prime_item_nbr as original_item_num
from ssa
join smax smax1 -- first join for smax.
on ssa.prime_item_nbr = smax1.prime_item_nbr -- gives the prime item nbr the most current description
left join smax smax2 --second join for smax -- assigned the prime item nbr the latest nbr
on smax1.prime_item_desc = smax2.prime_item_desc
and smax2.is_overwriting_item_num =1 -- only joins to item numbers that are being overwritten
left join  mcl -- bringing in cleaned up store data for finding most current item number
on ssa.prime_item_nbr = mcl.item_id
)
select * 
from details
)
;
