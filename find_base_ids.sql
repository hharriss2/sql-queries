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