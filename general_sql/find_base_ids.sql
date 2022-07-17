/*START*/
--this query is used to find new group id's. pairs together a tool id with any base id its already had
/*START BID1*/
			with r as 
				(-- find unique instance of an item id, its base upc, and sale date
				select distinct item_id, base_upc, sale_date
				from retail_link_pos
				)
			, base_ids as 
				(SELECT wm_catalog2.item_num,
			            wm_catalog2.item_id as base_id,
			            "left"(wm_catalog2.gtin, 13) AS gtin,
			            wm_catalog2.item_description
			           FROM wm_catalog2
				)
			,max_dates as 
				(
				select item_id, max(sale_date) as date_compare
				from retail_link_pos 
				group by item_id 
				)
			select distinct r.item_id, base_ids.base_id::integer
			from r 
			join max_dates
			on r.item_id = max_dates.item_id and r.sale_date = max_dates.date_compare
			join base_ids 
			on r.base_upc = base_ids.gtin
			/*END BID1*/
        ),bid2 AS (
        /*START BID2*/
			with r as 
				(-- find unique instance of an item id, its base upc, and sale date
				select distinct item_id, base_upc, sale_date
				from retail_link_pos
				)
			, base_ids as 
				(-- create table for item id and its base upc 
				select distinct item_id as base_id, base_upc
				from retail_link_pos 
				where upc = base_upc
				)
			,max_dates as 
				(
				select item_id, max(sale_date) as date_compare
				from retail_link_pos 
				group by item_id 
				)
			select distinct r.item_id::integer, base_ids.base_id::integer
			from r 
			join max_dates
			on r.item_id = max_dates.item_id and r.sale_date = max_dates.date_compare
			join base_ids 
			on r.base_upc = base_ids.base_upc
			/*END BID2*/
/*END*/

/*START*/
--this query contains the process for uploading lookups.curernt_base_id
--the lookup table goes off of group id to base id assignment.
--the lookup is later implimented in the com and stores tables
create view misc_views.find_base_ids1 as (--query finds the most recent base id's for group id
 WITH bid1 AS (--first method of searching goes by matching item 360 upc with retail sales
         WITH r AS (
                 SELECT DISTINCT retail_link_pos.item_id::integer,
                    retail_link_pos.base_upc,
                    retail_link_pos.sale_date
                   FROM retail_link_pos
                ), base_ids AS (
                 SELECT wm_catalog2.item_num,
                    wm_catalog2.item_id AS base_id,
                    "left"(wm_catalog2.gtin, 13) AS gtin,--converting gtin to upc
                    wm_catalog2.item_description
                   FROM wm_catalog2
                   
                ), max_dates AS (
                 SELECT retail_link_pos.item_id::integer,
                    max(retail_link_pos.sale_date) AS date_compare
                   FROM retail_link_pos
                  
                  GROUP BY retail_link_pos.item_id
                )
         SELECT DISTINCT r_1.item_id, base_id::integer, group_id
           FROM r r_1
             JOIN max_dates ON r_1.item_id = max_dates.item_id AND r_1.sale_date = max_dates.date_compare
             JOIN base_ids ON r_1.base_upc = base_ids.gtin
             left join group_ids g 
             on r_1.item_id = g.tool_id
              
        ), bid2 AS (--second search looks to compare upc to base upc for retail sales
         WITH r AS (
                 SELECT DISTINCT retail_link_pos.item_id::integer,
                    retail_link_pos.base_upc,
                    retail_link_pos.sale_date
                   FROM retail_link_pos
                ), base_ids AS (
                 SELECT DISTINCT retail_link_pos.item_id AS base_id,
                    retail_link_pos.base_upc
                   FROM retail_link_pos
                  WHERE retail_link_pos.upc = retail_link_pos.base_upc
                ), max_dates AS (
                 SELECT retail_link_pos.item_id,
                    max(retail_link_pos.sale_date) AS date_compare
                   FROM retail_link_pos
                  GROUP BY retail_link_pos.item_id
                )
         SELECT DISTINCT r_1.item_id, base_id, group_id
           FROM r r_1
             JOIN max_dates ON r_1.item_id = max_dates.item_id AND r_1.sale_date = max_dates.date_compare
             JOIN base_ids ON r_1.base_upc = base_ids.base_upc
             left join group_ids g 
             on g.tool_id = r_1.item_id

        ), r AS (
         SELECT rs1.id,
            rs1.tool_id::integer AS item_id,
            rs1.product_name,
            rs1.upc,
            tb.brand_name,
            rs1.base_upc,
            rs1.sale_date,
            rs1.wm_week,
            rs1.units,
            rs1.sales,
            2 AS retail_type_id
           FROM pos_reporting.retail_sales rs1
             LEFT JOIN lookups.tool_brand_tbl tb ON tb.tool_id = rs1.tool_id
        ),max_bid as (
        	select item_id, max(sale_date) as mb_date_compare
        	from retail_link_pos 
        	group by item_id
        )
 SELECT DISTINCT --bid1 and bid2 have different search results. we want to append all group id's found together
    COALESCE(bid1.base_id, bid2.base_id) AS base_id,
    coalesce(bid1.group_id, bid2.group_id) as group_id,
    mb_date_compare
   FROM r
     LEFT JOIN bid1 ON r.item_id = bid1.item_id
     LEFT JOIN bid2 ON r.item_id = bid2.item_id
     left join max_bid on max_bid.item_id = r.item_id
)
     ;
create view misc_views.find_base_ids2 as (--second step in uploading the base id's to the lookup table
select max(f1.base_id) as base_id, f1.group_id --2. find the max item id. not completely accurate but acceptable
from misc_views.find_base_ids1 f1
join (
	select group_id, max(mb_date_compare) as date_compare_1 --1. self joins to find base id with max date
	from misc_views.find_base_ids1
	group by group_id
		) f2
on f1.group_id = f2.group_id and f1.mb_date_compare = f2.date_compare_1
group by f1.group_id
)
;    
truncate lookups.current_base_id;--run these two to complete
insert into lookups.current_base_id(group_id, base_id)
select group_id, base_id
from misc_views.find_base_ids2;
/*END*/