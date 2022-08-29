create or replace view scrape_data.every_day_retail as (
    --finds the every day retail- retail that has been scraped the most. Does not include retails during promo's 
select *
from (
select item_id
	,((price_retail *.1) *10)::numeric(10,0)  as price_retail
	,min(date_inserted) as date_inserted
	,count(distinct date_inserted) scraped_at_retail
	,row_number() over (partition by item_id order by count(distinct date_inserted) desc) count_rank
from (-- scrape tbl + promo range SQ
	  -- Identify Item Id's that were scraped during Promo and Omit those
	select * 
	from scrape_data.scrape_tbl sc
	left join pos_reporting.promo_range pr
	on sc.item_id = pr.tool_id
	and sc.date_inserted >pr.start_date
	and sc.date_inserted <=pr.end_date
	and item_id in (select item_id from lookups.tool_id_numeric)
	) t1
where promo_bool is null
group by item_id
	,((price_retail *.1) *10)::numeric(10,0) 
) t1
where count_rank = 1

)
;
