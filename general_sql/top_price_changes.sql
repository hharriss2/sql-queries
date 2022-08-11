with 
	l4 as 
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
		)
	,l13 as 
		(
		select tool_id::integer
				, l13_units
		from(
			select rs.tool_id
			, (sum(units)/13::numeric(10,2))::numeric(10,2) l13_units
			-- use divided by 4 to account for OOS. Idealy is should sell every week
			from pos_reporting.retail_sales rs
			where wm_week in (-- finds the last 4 full weeks of sales
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
		)
	,l52 as 
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
		)
	,price_change as 
		(
		select *
		from
		(
			select distinct 
				t1.item_id
				--row number assigns incrament of 1 to items when 'early_date' changes restarts row number on new item id
				,row_number() over(partition by t1.item_id order by t1.item_id, t2.date_inserted) as final_row_num
				,l1.base_id
				,l1.cat as category
				,l1.division
				,l1.wm_name
				,l1.group_id
				,l1.model_name
				,t1.date_inserted as recent_date
				, t2.date_inserted previous_date
				, t1.price_retail as recent_retail
				, t2.price_retail as previous_retail
				,case when t2.price_retail is not null
				then ((t1.price_retail-t2.price_retail) /(t2.price_retail))::numeric(10,2)
				else 0 end as recent_over_early_retail
				,coalesce(t1.on_promo_bool, 'No') as on_promo_bool
			from scrape_data.price_change t1
			join scrape_data.price_change t2
			on t1.item_id = t2.item_id
			left join lookups.lookup_tbl l1
			on t1.item_id = l1.item_id
			where 1=1
			and (-- row num can be combo of 1&2 or 1&1
					(t1.row_number = 1 and t2.row_number = 2)
				or 
					(t1.row_number = 1 and t2.row_number = 1)
				)
		) t1
		where final_row_num = 1
		and item_id in (select tool_id::integer from temp_tool_ids)	
		)
select
	price_change.item_id
	,base_id
	,category
	,division
	,wm_name
	,group_id
	,model_name
	,recent_date
	,previous_date
	,recent_retail
	,previous_retail
	,(recent_over_early_retail *100)::numeric(10,2) as recent_over_early_retail
	,l52_units
	,l13_units
	,l4_units
	,on_promo_bool
	,((l4_units - l52_units) / l52_units * 100)::numeric(10,2) AS l4_52_change
from price_change 
left join l52
on price_change.item_id = l52.tool_id
left join l13
on price_change.item_id = l13.tool_id
left join l4
on price_change.item_id = l4.tool_id
where ((l4_units - l52_units) / l52_units * 100) > .3

;