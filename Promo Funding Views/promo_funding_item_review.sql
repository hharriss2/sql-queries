select distinct pf.model
				,case when pr.division = 'Dorel Home Products' then 'DHP'
				when pr.division = 'Dorel Asia' then 'Dorel Living' else 
				pr.division end as division
				, cbm.cat
				, pf.tool_id
				,pr.product_name
				, pf.sum_units promo_units
				, pf.sum_sales as promo_sales
				, funding_amt
				, funding_total
				,pf.count_week as promo_week_count
				, count_weeks.count_week LY_week_count
				, sum_units.sum_units LY_units
				, sum_units.sum_sales LY_sales
from 
	(--wrapping querie to find the count of weeks
	select model
		,tool_id
		,count(distinct wm_week) count_week
		,sum(sum_units) sum_units
		,funding_amt
		,sum(funding_total) as funding_total
		,sum(sum_sales) as sum_sales
	from
	( -- sum of sales for item during promo 
		select model
			,tool_id
			,wm_week
			, sum(units) sum_units
			, funding_amt
			, sum(sales_funding) funding_total
			, sum(sales) as sum_sales
		from
			(
				SELECT DISTINCT pf.id,
				    s.id AS sid,
				    pf.model,
				    s.wm_week,
				    pf.tool_id,
				    s.units,
				    pf.funding_amt,
				    pf.promo_type,
				    pf.start_date,
				    pf.end_date,
				    pf.submit_date AS submit_week,
				    pf.suggested_retail,
				    pf.product_name,
				    (s.units::numeric * pf.funding_amt)::numeric(10,2) AS sales_funding,
				    s.sales::real AS sales
				   FROM pos_reporting.retail_sales s
				     RIGHT JOIN pos_reporting.promo_funding_clean pf ON s.tool_id::integer = pf.tool_id
				  WHERE s.wm_week >= pf.start_date AND s.wm_week <= pf.end_date AND pf.funding_amt > 0::numeric
				  --show only sales between week 1 and 13
--				  and s.wm_week >=202301 
--				  and s.wm_week <=202313
				  and promo_type = 'Tax Time 2022'-- only need tax time promo
			) pf
--			where tool_id = '15063498'
		group by model, tool_id,wm_week, funding_amt
		having sum(units) >0 -- omiting any promos that did less than 0 as a whole
		) pf
		group by model, tool_id, funding_amt
			)pf
left join 
	(-- sum of sales for 2021 by item
	select * 
	from
		(
		select tool_id, sum(sum_units) as sum_units, sum(sum_sales ) as sum_sales
		from (  --finds 
		  select distinct tool_id, wm_week, sum(units) as sum_units, sum(sales) as sum_sales
		  from pos_reporting.retail_sales
		  where tool_id::integer in 
							(/*Certian promo items. 
							Ran select distinct tool id from promo type*/
							select tool_id::integer 
							from temp_tool_ids
							)
		  and wm_week >=202201 and wm_week <=202252
		  group by tool_id, wm_week
		  	) t1
		  where sum_units >0 
		  --have to omit 0 units after they've been summed 
		  group by tool_id
		  
	
		) sum_units
	) sum_units
on sum_units.tool_id::integer = pf.tool_id
left join 
	(
	select * 
	from  
	 ( -- same logic as getting 2021 sales. However this time we want to get a week count
	select tool_id, count(distinct wm_week) as count_week
	from
	  (
	  select distinct tool_id, wm_week, sum(units) as sum_units 
	  from pos_reporting.retail_sales
	  where tool_id::integer in (select tool_id::integer from temp_tool_ids)
	  and wm_week >=202201 and wm_week <=202252
	  group by tool_id, wm_week
	  ) t1
	 where  sum_units >0
	 group by tool_id
	 )count_weeks
	)count_weeks
on pf.tool_id = count_weeks.tool_id::integer
left join products_raw pr 
on pr.model = pf.model 
left join cat_by_model cbm 
on cbm.model = pf.model 
where division in ('Ameriwood', 'Dorel Asia','Dorel Home Products')