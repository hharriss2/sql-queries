--select * 
--from misc_views.top_gainers;
--
--CREATE TABLE top_gainer_history (
--    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--    model text,
--    tool_id text,
--    product_name text,
--    inserted_at timestamp with time zone DEFAULT now()
--);
--create or replace view misc_views.top_gainers as (
 SELECT t1.tool_id AS "Tool ID",
    t1.group_id AS "Group ID",
    t1.model AS "Model",
    t1.product_name AS "Product Name",
    t1.category_name AS "Category",
    t1.account_manager AS "Account Manager",
    t1.l4_units AS "Last 4 Average Units Sold",
    t1.l52_units AS "Last 52 Average Units Sold",
    t1.l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
   FROM ( SELECT DISTINCT t1.tool_id,
            model_tool.model,
            p.product_name,
            c.category_name,
            a.account_manager,
            g.group_id,
            t1.l4_units,
            t2.l52_units,
            (t1.l4_units - t2.l52_units) / t2.l52_units * 100::numeric AS l4_52_change 
	from 
	(
		select tool_id::integer
				, l4_units
		from(
			select rs.tool_id
			, (sum(units)/4::numeric(10,2))::numeric(10,2) l4_units
			-- use divided by 4 to account for OOS. Idealy is should sell every week
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
			)l4_units_sold--groups up sum of units by week then omits less than 0 
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
--				and units >0
				group by rs.tool_id
			)l52_units_sold
			where l52_units >0 
		) t2
	on t1.tool_id = t2.tool_id
	left join 
		(
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
	left join products_raw p 
	on p.model = cbm.model
	left join group_ids g
	on t1.tool_id = g.tool_id
	where 1=1
	and( t1.tool_id in 
				(
				select tool_id::integer
				from item_class-- new table item_class. this list came from z drive- item 'ABC AnalysisFinal.xlsx'
				where class = 'A'
				)
	or cat = 'Mattresses')--parenthesis say it can be an A item or be a mattress
	and ((l4_units - l52_units))/(l52_units) >=.30--finds percentages only  30% or over
	and model_tool.model is not null
	)t1
	;
/*BY GROUP ID*/
SELECT 
    t1.group_id AS "Group ID",
    t1.collection_name AS "Collection Name",
    t1.category_name AS "Category",
    t1.account_manager AS "Account Manager",
    t1.l4_units AS "Last 4 Average Units Sold",
    t1.l52_units AS "Last 52 Average Units Sold",
    t1.l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
   FROM ( SELECT DISTINCT 
            c.category_name,
            a.account_manager,
            t1.group_id,
            t1.collection_name,
            t1.l4_units,
            t2.l52_units,
            (t1.l4_units - t2.l52_units) / t2.l52_units * 100::numeric AS l4_52_change 
	from 
	(
		select group_id
				,collection_name
				, l4_units
				,tool_id
		from(
			select group_id
			,collection_name
			, (sum(units)/4::numeric(10,2))::numeric(10,2) l4_units
			,max(rs.tool_id::integer) as tool_id
			-- use divided by 4 to account for OOS. Idealy is should sell every week
			from pos_reporting.retail_sales rs
			left join group_ids g on g.tool_id  = rs.tool_id::Integer
			where wm_week in (-- finds the last 4 full weeks of sales
								select distinct wm_week
								from pos_reporting.retail_sales 
								where wm_week != (select max(wm_week)-- filters non full week
								from pos_reporting.retail_sales)
								order by wm_week desc
								limit 4
							)
			group by group_id, collection_name
			)l4_units_sold--groups up sum of units by week then omits less than 0 
			where l4_units > 0
	) t1
	left join
	 (
		select group_id
			,collection_name
			, l52_units
			,tool_id
		from 
			(
			select group_id
			,collection_name
			, (sum(units)/count(distinct wm_week)::numeric(10,2))::numeric(10,2) l52_units
			,max(rs.tool_id::integer) as tool_id
			from pos_reporting.retail_sales rs
			join group_ids g
			on rs.tool_id::integer = g.tool_id
				where wm_week in (-- same as last 4 except with las t52
						select distinct wm_week
						from pos_reporting.retail_sales 
						where wm_week != (select max(wm_week) from pos_reporting.retail_sales)
						order by wm_week desc
						limit 52
							)
				and units >0
				group by group_id, collection_name
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
	left join products_raw p 
	on p.model = cbm.model
	where 1=1
	and( t1.group_id in 
				(
				select group_id
				from group_ids
				where tool_id in 
					(
					select tool_id::integer
					from item_class-- new table item_class. this list came from z drive- item 'ABC AnalysisFinal.xlsx'
					where class = 'A'
					)
						
				)
	or cat = 'Mattresses')--parenthesis say it can be an A item or be a mattress
	and ((l4_units - l52_units))/(l52_units) >=.30--finds percentages only  30% or over
	)t1