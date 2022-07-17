--this query gives the last 4, 13, and 52 weeks for pos. 
--mostly taken from laggers and gainers

SELECT DISTINCT t1.tool_id,
            model_tool.model,
            t1.l4_units,
            t3.l13_units,
            t2.l52_units 
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
				group by rs.tool_id
			)l52_units_sold
			where l52_units >0 
		) t2
	on t1.tool_id = t2.tool_id
	left join 
	(
		select tool_id::integer
				, l13_units
		from(
			select rs.tool_id
			, (sum(units)/13::numeric(10,2))::numeric(10,2) l13_units
			-- use divided by 13 to account for OOS. Idealy is should sell every week
			from pos_reporting.retail_sales rs
			where wm_week in (-- finds the last 13 full weeks of sales
								select distinct wm_week
								from pos_reporting.retail_sales 
								where wm_week != (select max(wm_week)-- filters non full week
								from pos_reporting.retail_sales)
								order by wm_week desc
								limit 13
							)
			group by rs.tool_id
			)l13_units_sold--groups up sum of units by week then omits less than 0 
			where l13_units > 0
	) t3
	on t2.tool_id = t3.tool_id
	left join 
		(
		select model, item_id::integer as tool_id 
		from clean_data.master_com_list
		)model_tool
	on model_tool.tool_id = t1.tool_id)