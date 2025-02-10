create or replace view etl_views.store_current_item_master_insert_view as 
(
with smax_s1 as  --sales max step 1
(-- find the max relation for a item description to an item number. 
SELECT DISTINCT 
	prime_item_nbr
	,prime_item_desc
    ,max(daily) AS last_sale_date
    ,max(daily) over (partition by prime_item_nbr) as last_sale_date_item_nbr
FROM sales_stores_auto
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

select distinct
	smax2.prime_item_nbr as current_item_num
	,smax1.prime_item_desc
	,smax1.prime_item_nbr
from smax smax1
left join smax smax2
on smax1.prime_item_desc = smax2.prime_item_desc
and smax2.is_overwriting_item_num =1 -- only joins to item numbers that are being overwritten
--where smax1.prime_item_nbr ='7103626'
)
;