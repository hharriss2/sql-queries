select tool_id "Tool ID"
, available "Is Available?"
,model "Model"
, product_name "Product Name"
, category_name "Category"
, account_manager "Account Manager"
, l4_units "Last 4 Average Units Sold"
, l52_units "Last 52 Average Units Sold"
,(l4_52_change::integer || '%') as "Last 4 % Chnage Vs Last 52"
from(
	select distinct  t1.tool_id 
	, case when mrs.available = 'TRUE' THEN 'Available' when mrs.available =  'FALSE' then 'Unavailable'
	else null end as available
	,model_tool.model 
	, p.product_name 
	,c.category_name 
	,a.account_manager 
	,l4_units 
	, l52_units 
	,  (((l4_units - l52_units))/(l52_units)) * 100  l4_52_change 
	from 
	(
		select tool_id
		, (sum(units)/count(distinct wm_week)::numeric(10,2))::numeric(10,2) l4_units
		from misc_views.retail_sales
		where wm_week in (-- finds the last 4 full weeks of sales
							select distinct wm_week
							from misc_views.retail_sales 
							where wm_week != (select max(wm_week)-- filters non full week
							from misc_views.retail_sales)
							order by wm_week desc
							limit 4
						)
		and units >0
		group by tool_id
	) t1
	left join
	 (
	select tool_id
	, (sum(units)/count(distinct wm_week)::numeric(10,2))::numeric(10,2) l52_units
	from misc_views.retail_sales
		where wm_week in (-- same as last 4 except with las t52
				select distinct wm_week
				from misc_views.retail_sales 
				where wm_week != (select max(wm_week) from misc_views.retail_sales)
				order by wm_week desc
				limit 52
					)
		and units >0
		group by tool_id
		) t2
	on t1.tool_id = t2.tool_id
	left join 
		(
			select distinct s.model, s.tool_id
			from ( --finds the model's most recent ship date
					select tool_id, max(date_shipped) as date_compare 
					from ships_schema.ships
					where retailer='Walmart.com'-- filter walmart.com to only find tool id's on .com sales
					and tool_id !=''-- anomoly of having blank tool id 
					group by tool_id
				  ) ship_model
			join ships_schema.ships s  
			on s.tool_id = ship_model.tool_id --compares max ship date to get a model tool id relation 
			where 1=1
			and date_shipped = date_compare
			and s.retailer ='Walmart.com'
			and s.tool_id !=''
		)model_tool
	on model_tool.tool_id = t1.tool_id
	left join cat_by_model cbm --pull category
	on model_tool.model = cbm.model --pull model 
	left join category c -- link category to account manager
	on c.category_name = cbm.cat
	left join account_manager a --find accoutn manager
	on c.am_id = a.account_manager_id -- finally joining int instead of text 
	left join scrape_data.most_recent_scrape mrs-- joins scraper to find availability
	on mrs.item_id::text = model_tool.tool_id
	left join products_raw p on cbm.model = p.model -- joins pims to find product raws
	where 1=1
	and( 
			t1.tool_id in 
						(
						select tool_id
						from item_class-- new table item_class. this list came from z drive- item 'ABC AnalysisFinal.xlsx'
						where class = 'A'
						)
			or cat = 'Mattresses'
		 )--parenthesis say it can be an A item or be a mattress
	and ((l4_units - l52_units))/(l52_units) < 0--finds percentages above 0
	and model_tool.model is not null
	)t1 ;
