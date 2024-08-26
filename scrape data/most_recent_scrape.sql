--powers the buy box report on BV sharing workspace
--finds the most recent scrape for an item where the scraped data is found
create or replace view scrape_data.most_recent_scrape as 
(
with mi as 
(
select distinct item_id, max(date_inserted) date_inserted
from scrape_data.scrape_tbl
where 1=1
and date_inserted >= current_date - interval '30 days'
-- and product_name is not null -- omits any items that the scraper did not find
-- and product_name != 'Product not Found'
group by item_id
)
,md as --max date
(
select max(date_inserted) as max_date
from mi
)
select s.*
    ,case
    when s.date_inserted = md.max_date
    then 1 
    else 0
    end as is_today_scrape
from scrape_data.scrape_tbl s
join mi 
on s.item_id = mi.item_id
and mi.date_inserted = s.date_inserted
left join md
on 1=1
)