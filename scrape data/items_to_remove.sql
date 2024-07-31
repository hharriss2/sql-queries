
--some sql logic to find items to remove from scrape
--step 1. create a materialized view for items to find available and non availability
--not included in query, but maybe filter for the most recent item id's provided by xbyte
 SELECT scrape_tbl.item_id,
    max(
        CASE
            WHEN scrape_tbl.available = true THEN scrape_tbl.date_inserted
            ELSE NULL::date
        END) AS latest_available_status,
    max(
        CASE
            WHEN scrape_tbl.available = false THEN scrape_tbl.date_inserted
            ELSE NULL::date
        END) AS latest_unavailable_status
   FROM scrape_data.scrape_tbl
  GROUP BY scrape_tbl.item_id;

  --step 2. run analysis
with t1 as 
(
select * 
	,case
		when latest_available_status is null
		then 1
		when latest_unavailable_status > latest_available_status
		then 1
		else 0
		end as currently_unavailable

from temp_scrape_available
)
,t2 as 
(
select *
	,case
		when latest_available_status is null and latest_unavailable_status is null
		then 0
		when latest_available_status is null
		then current_date - latest_unavailable_status
		when currently_unavailable =1 and latest_available_status <latest_unavailable_status
		then current_date - latest_available_status
		else null
		end as days_unavailable
from t1
)
,rs as 
(
select tool_id::bigint as item_id
	,max(sale_date) as latest_sale_date
	,sum(sales) as total_sales
from pos_reporting.retail_sales
group by tool_id::bigint
)
,csi as --current scraped items
(
select btrim(item_id,'  ')::bigint as item_id
from scrape_tbl_staging
where product_name is null
)
select t2.item_id
	,latest_available_status
	,latest_unavailable_status
	,days_unavailable
	,latest_sale_date
	,total_sales
	,case
		when days_unavailable = 0 and latest_sale_date is not null
		then 'No Site Record or really Old Item'
		else null
		end as is_old_item
from t2
left join rs 
on t2.item_id = rs.item_id
where days_unavailable is not null
and days_unavailable =100
and current_date - latest_sale_date >=365
and t2.item_id in (select item_id from csi)