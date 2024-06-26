--like the search tool id's query except this one uses scrape data instead
 create or replace view misc_views.search_tool_ids_scrape as 
 (
 WITH bid1 AS  -- base id 1
 (
SELECT DISTINCT 
	t1.item_id
	,t1.base_id
FROM scrape_data.scrape_tbl t1
)
SELECT DISTINCT 
	bid2.item_id AS search_item_id -- use this id when looking up item numbers
    ,bid1.item_id -- item id from the join
    ,bid1.base_id -- base id's from joins
FROM bid1
JOIN bid1 as bid2 
ON bid1.base_id = bid2.base_id -- item id's with the same base id will join on eachother 
--self joining will give duplicate item id's. it joins any item id that has the same base id onto itself
 )
     ;