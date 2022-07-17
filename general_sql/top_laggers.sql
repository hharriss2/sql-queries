 SELECT t1.tool_id AS "Tool ID",
    group_id AS "Group ID",
    t1.model AS "Model",
    t1.available AS "Is Available?",
    t1.product_name AS "Product Name",
    t1.category_name AS "Category",
    t1.account_manager AS "Account Manager",
    t1.l4_units AS "Last 4 Average Units Sold",
    t1.l52_units AS "Last 52 Average Units Sold",
    t1.l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
from(
	select distinct  t1.tool_id
	, case when mrs.available = 'TRUE' THEN 'Available' when mrs.available =  'FALSE' then 'Unavailable'
	else null end as available
	,model_tool.model 
	, p.product_name 
	,c.category_name 
	,g.group_id
	,a.account_manager 
	,l4_units 
	, l52_units 
	,  case when l52_units <= 0 
		then null 
		else (((l4_units - l52_units))/(l52_units)) * 100  
		end as l4_52_change 
	from 
	(
		select tool_id::integer
				, l4_units
		from(
			select rs.tool_id
			, (sum(units)/4::numeric(10,2))::numeric(10,2) l4_units
			from pos_reporting.retail_sales rs
			where wm_week in (-- finds the last 4 full weeks of sales
								select distinct wm_week
								from pos_reporting.retail_sales 
								where wm_week != (select max(wm_week)-- filters non full week
								from pos_reporting.retail_sales)
								order by wm_week desc
								limit 4
							)
			group by rs.tool_id
			)l4_units_sold
			where l4_units > 0 
	) t1
	left join
	 (
		select tool_id::integer, l52_units
		from 
			(
			select rs.tool_id
			, (sum(units)/count(distinct wm_week)::numeric(10,2))::numeric(10,2) l52_units
			from pos_reporting.retail_sales rs
				where wm_week in (-- same as last 4 except with las t52
						select distinct wm_week
						from pos_reporting.retail_sales 
						where wm_week != (select max(wm_week) from pos_reporting.retail_sales)
						order by wm_week desc
						limit 52
							)
				and units >0 --not having returns is ideal for 52 weeks
				group by rs.tool_id
			)l52_units_sold
			where l52_units >0 
		) t2
	on t1.tool_id = t2.tool_id
	left join 
		(
--			select distinct s.model, s.tool_id
--			from ( --finds the model's most recent ship date
--					select tool_id, max(date_shipped) as date_compare 
--					from ships_schema.ships
--					where retailer='Walmart.com'-- filter walmart.com to only find tool id's on .com sales
--					and tool_id !=''-- anomoly of having blank tool id 
--					group by tool_id
--				  ) ship_model
--			join ships_schema.ships s  
--			on s.tool_id = ship_model.tool_id --compares max ship date to get a model tool id relation 
--			where 1=1
--			and date_shipped = date_compare
--			and s.retailer ='Walmart.com'
--			and s.tool_id !=''
		select model, item_id::integer as tool_id 
		from clean_data.master_com_list
		)model_tool
	on model_tool.tool_id = t1.tool_id
	left join cat_by_model cbm --pull category
	on model_tool.model = cbm.model --pull model 
	left join category c -- link category to account manager
	on c.category_name = cbm.cat
	left join account_manager a --find accoutn manager
	on c.am_id = a.account_manager_id -- finally joining int instead of text 
	left join scrape_data.most_recent_scrape mrs-- joins scraper to find availability
	on mrs.item_id = model_tool.tool_id
	left join products_raw p on cbm.model = p.model -- joins pims to find product raws
	left join group_ids g 
	on g.tool_id = t1.tool_id
	where 1=1
	and( 
			t1.tool_id in 
						(
						select distinct ic.tool_id::integer
						from item_class ic-- new table item_class. this list came from z drive- item 'ABC AnalysisFinal.xlsx'
						where class = 'A'

						)
			or cat = 'Mattresses'
		 )--parenthesis say it can be an A item or be a mattress
--	and t1.group_id in 
--		(
--		select group_id from temp_group_id_view
--		)
	and model_tool.model is not null
	and t2.l52_units >=15
	and ((l4_units - l52_units))/(l52_units) < -.10
	)t1
	
	;

/*BY GROUP ID*/ --test
SELECT 
    group_id AS "Group ID",
    collection_name as "Collection Name",
    t1.category_name AS "Category",
    t1.account_manager AS "Account Manager",
    t1.l4_units AS "Last 4 Average Units Sold",
    t1.l52_units AS "Last 52 Average Units Sold",
    t1.l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
from(
	select distinct 
	c.category_name 
	,t1.group_id
	,t1.collection_name
	,a.account_manager 
	,l4_units 
	, l52_units 
	,  case when l52_units <= 0 
		then null 
		else (((l4_units - l52_units))/(l52_units)) * 100  
		end as l4_52_change 
	from 
	(
		select group_id
			   ,collection_name
				, l4_units
				,tool_id
		from(
			select g.group_id, g.collection_name
			, (sum(units)/4::numeric(10,2))::numeric(10,2) l4_units
			,max(rs.tool_id::integer) as tool_id
			from pos_reporting.retail_sales rs
			left join group_ids g 
			on rs.tool_id::integer = g.tool_id
			where wm_week in (-- finds the last 4 full weeks of sales
								select distinct wm_week
								from pos_reporting.retail_sales 
								where wm_week != (select max(wm_week)-- filters non full week
								from pos_reporting.retail_sales)
								order by wm_week desc
								limit 4
							)
			group by g.group_id, g.collection_name
			)l4_units_sold
			where l4_units > 0 
	) t1
	left join
	 (
		select group_id, l52_units
		from 
			(
			select g.group_id
			, (sum(units)/count(distinct wm_week)::numeric(10,2))::numeric(10,2) l52_units
			from pos_reporting.retail_sales rs
			left join group_ids g 
			on rs.tool_id::integer = g.tool_id
				where wm_week in (-- same as last 4 except with las t52
						select distinct wm_week
						from pos_reporting.retail_sales 
						where wm_week != (select max(wm_week) from pos_reporting.retail_sales)
						order by wm_week desc
						limit 52
							)
				and units >0--not having any returns is ideal situation
				group by group_id
			)l52_units_sold
			where l52_units >0 
		) t2
	on t1.group_id = t2.group_id
	left join clean_data.master_com_list  mcl
	on  mcl.item_id = t1.tool_id
	left join cat_by_model cbm --pull category
	on  mcl.model = cbm.model --pull model 
	left join category c -- link category to account manager
	on c.category_name = cbm.cat
	left join account_manager a --find accoutn manager
	on c.am_id = a.account_manager_id -- finally joining int instead of text 
	left join products_raw p on cbm.model = p.model -- joins pims to find product raws
	where 1=1
	and( 
			t1.group_id in 
						(
						select group_id 
						from group_ids
						where tool_id in (
						select distinct tool_id::integer
						from item_class ic-- new table item_class. this list came from z drive- item 'ABC AnalysisFinal.xlsx'
						where class = 'A'
						)

						)
			or cat = 'Mattresses'
		 )--parenthesis say it can be an A item or be a mattress
--	and t1.group_id in 
--		(
--		select group_id from temp_group_id_view
--		)
--	and  mcl.model is not null
	and t2.l52_units >=15
	and ((l4_units - l52_units))/(l52_units) < -.10
	)t1