/*Finding recent retails for an item
  this query calculates prices based on a count of how many times an Item has been scraped

Min_price – finds the lowest price out of the 4 days when the item was last scraped
Avg price- sum of retail prices/ number of days scraped (days average)
Earliest date- the earliest of the most recent 4 days an item was scraped
Days_average – the most recent scrape for an item not exceeding 90 scrapes.*/
select 
	item_id
	,min(min_price) as min_price
	,(sum(price_retail)/ sum(date_count))::numeric(10,2) as avg_price
	,min(min_date) as earliest_date
	,sum(date_count) as days_average
from
(
	select 
		item_id
		, case when rn <=4 then min(price_retail)
		else null end as min_price
		,case when rn <=4 then min(date_inserted) 
		else null end as min_date
		,case when rn <=90 then price_retail
		end as price_retail
		,case when rn <=90 then count(distinct date_inserted)  else null end as date_count
	from 
		(
		select 
			item_id
			, date_inserted
			, row_number() over (partition by item_id order by date_inserted desc) as rn
			, st.price_retail
		from scrape_data.scrape_tbl st
		where 1=1 
		) t1
		where 1=1  
--		and item_id = 883205
		group by item_id, rn, price_retail 
) t2
group by item_id;


/*Like the query above, however this query scrapes strictly on:
the last 4 distinct scrape days 
the last 90 distinct scrape days*/

select distinct coalesce(t1.item_id,t2.item_id) item_id, avg_retail_l90, min_retail_l4
from (

	select item_id, avg(price_retail)::numeric(10,2) avg_retail_l90
	from scrape_data.scrape_tbl
	where date_inserted in 
	(
	select distinct date_inserted
	from scrape_data.scrape_tbl
	order by date_inserted desc
	limit 90
	) 
	group by item_id
	)t1
full join 
	(
	select item_id, min(price_retail) min_retail_l4
	from scrape_data.scrape_tbl
	where date_inserted in 
	(
	select distinct date_inserted
	from scrape_data.scrape_tbl
	order by date_inserted desc
	limit 4
	) 
	group by item_id
	) t2
on t1.item_id = t2.item_id;



/*FIND PRICE CHANGES*/
--find the most recent price for an item and the last date it changed prices
select * 
from (
	select distinct 
		item_id
		, price_retail
		, price_was
		, date_inserted
		--row number assigns incramental value of 1 starting off on most recent scrape
		--resent to 1 when there is a new item id
		,row_number() over(partition by item_id order by item_id, date_inserted desc)
	from (
		select -- find where an item's retail changes
			item_id
			, price_retail
			, price_was
			, date_inserted 
			--row number assigns incramental value starting at 1. resets to 1 when an item's retail changes
			,row_number() over(partition by item_id, price_retail order by date_inserted desc)
		from scrape_data.scrape_tbl
		where price_retail is not null
		) t1
	where row_number = 1-- only looking for the retail change
	and item_id in (select tool_id::integer from temp_tool_ids)
	order by item_id, date_inserted desc
	)t2
where row_number in (1,2) -- only care about most recent changes for an item id
;