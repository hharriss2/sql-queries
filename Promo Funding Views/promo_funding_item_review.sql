/*Step 1, this query is the working query that will be sent to the divisions
	-The query contains everyday units, sales, for promo and last years
*/
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
--and cbm.model = '2005019'
;


/*Step 2. Query compares 2021 aws to promo aws based off similar AURs
	-only calculates aws for 2021 if the aur is more than 5 of the promo*/
select distinct pf.model
	,sum_units.tool_id
	,pname.product_name
	--,sum_units.wm_week
	,avg(sum_units.sum_units)::numeric(10,2) as aws_2021
	--,aur_2021
	,promo_aur
	--, ((promo_aur-aur_2021)/(aur_2021))::numeric(10,2) as promo_over_ly_aur
	,(pf.sum_units/pf.count_week)::numeric(10,2) as aws_promo
	,case when ((pf.sum_units/pf.count_week)::numeric(10,2)) > avg(sum_units.sum_units) then 1
	else 0 end as below_promo_aws
	/*if 2021 aws is BELOW promo aws, give a 1*/
		,case when ((pf.sum_units/pf.count_week)::numeric(10,2)) < avg(sum_units.sum_units) then 1
	else 0 end as above_promo_aws
	/*if 2021 aws is ABOVE promo aws, give a 1*/
from	
	(/*same  as select before this one, but need to sub query to take out 0 units after week sum*/
	select tool_id, wm_week, sum_units, sum_sales,  (sum_sales/sum_units)::numeric(10,2) as aur_2021
	from
		(/*finds item id, wm week, sales, and aur*/
		select tool_id
		,wm_week
		, sum(sum_units) as sum_units
		, sum(sum_sales ) as sum_sales
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
		  group by tool_id, wm_week
		  
	
		) sum_units
	) sum_units
right join 
	(/*Has to subquery for counting weeks. We can then get the AWS For overall promo*/
	select model
		,tool_id
		,count(distinct wm_week) count_week
		,sum(sum_units) sum_units
		,funding_amt
		,sum(funding_total) as funding_total
		,sum(sum_sales) as sum_sales
		,(sum(sum_sales) / sum(sum_units))::numeric(10,2) as promo_aur
	from
		( 
		/*Has to regroup to omit 0's for the sum of the week*/
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
	) pf
on sum_units.tool_id = pf.tool_id::text
left join (select distinct product_name, item_id from retail_link_pos) pname
on pname.item_id = pf.tool_id
where 1=1
--and aur_2021   >= promo_aur -10
and aur_2021  >= promo_aur +5
--and sum_units.tool_id::integer in (select tool_id from pos_reporting.promo_funding_item_review pf where ((pf.promo_units - (pf.promo_week_count * (pf.ly_units/pf.ly_week_count)))/(pf.promo_week_count * (pf.ly_units/pf.ly_week_count) < 0
--)
group by 
pf.model
,sum_units.tool_id
,product_name
	--,sum_units.wm_week
	--,aur_2021
	,promo_aur
	--,((promo_aur-aur_2021)/(aur_2021))
	,(pf.sum_units/pf.count_week)::numeric(10,2)
	order by model
/*end for 2021 promo aur comparison*/
	;
/*This query calculates l13 for 2021 and 2020 and finds the deviance*/	

/*Step 3. Calculate Last 13 for  2021 over 2021
	-We use the last 13 weeks (40-52) specifically for finding a good average for the items before promo
	-Percents can get crazy to we cap out the limit to +-30%. Can vary*/
select distinct pf.model
		, pf.tool_id
		, pname.product_name
		,pf.promo_aur
		,(pf.sum_units/pf.count_week)::numeric(10,2) as promo_aws
		,(l13_2021.sum_units/l13_2021.wm_week)::numeric(10,2) as L13_2021_AWS
		,(l13_2020.sum_units/l13_2020.wm_week)::numeric(10,2) as L13_2020_AWS
		,case when  ((l13_2021.sum_units - l13_2020.sum_units)/(l13_2020.sum_units))::numeric(10,2) >.30
			then .30
			when ((l13_2021.sum_units - l13_2020.sum_units)/(l13_2020.sum_units))::numeric(10,2) <-.30
			then -.30
			else ((l13_2021.sum_units - l13_2020.sum_units)/(l13_2020.sum_units))::numeric(10,2)
		 end as L13_2021_over_2020_AWS
		,case when ((l13_2021.sum_units - l13_2020.sum_units)/(l13_2020.sum_units))::numeric(10,2) >0 
			then 1 
			else 0 
		 end as aws_gain
		,case when ((l13_2021.sum_units - l13_2020.sum_units)/(l13_2020.sum_units))::numeric(10,2) >0 
			then 0 
			else 1 
		 end as aws_loss 
		,l13_2021.sum_sales as sales_2021
		,l13_2020.sum_sales as sales_2020

from
	(/*Last 13 weeks for 2021*/
	select tool_id
		,count(distinct wm_week) as wm_week
		,sum(sum_units) as sum_units
		,sum(sum_sales) as sum_sales
		,(sum(sum_sales)/sum(sum_units))::numeric(10,2) as aur_2021
	from
		(/*finds item id, wm week, sales, and aur*/
		select tool_id
		,wm_week
		, sum(sum_units) as sum_units
		, sum(sum_sales ) as sum_sales

		from (  --finds 
		  select distinct tool_id, wm_week, sum(units) as sum_units, sum(sales) as sum_sales
		  from pos_reporting.retail_sales
		  where tool_id::integer in 
							(/*Certian promo items. 
							Ran select distinct tool id from promo type*/
							select tool_id::integer 
							from temp_tool_ids
							)
		  and wm_week in (select distinct wm_date::integer -100 as wm_date
		  				 from wm_calendar w
		  				 where  w.wm_year::integer = 2023
		  				 order by wm_date desc
		  				 limit 13
		  				 )
		  group by tool_id, wm_week
		  	) t1
		  where sum_units >0 
		  --have to omit 0 units after they've been summed 
		  group by tool_id
		  		, wm_week
		  
	
		) sum_units
		group by tool_id
	) l13_2021
right join 
	(/*Has to subquery for counting weeks. We can then get the AWS For overall promo*/
	select model
		,tool_id
		,count(distinct wm_week) count_week
		,sum(sum_units) sum_units
		,funding_amt
		,sum(funding_total) as funding_total
		,sum(sum_sales) as sum_sales
		,(sum(sum_sales) / sum(sum_units))::numeric(10,2) as promo_aur
	from
		( 
		/*Has to regroup to omit 0's for the sum of the week*/
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
	) pf
on pf.tool_id = l13_2021.tool_id::integer
right join
	(/*Last 13 weeks for 2020*/
	select tool_id
	 	,count(distinct wm_week) as wm_week
		, sum(sum_units) as sum_units
		, sum(sum_sales) as sum_sales
		, (sum(sum_sales)/sum(sum_units))::numeric(10,2) as aur_2020
	from
		(/*finds item id, wm week, sales, and aur*/
		select tool_id
		,wm_week
		, sum(sum_units) as sum_units
		, sum(sum_sales ) as sum_sales
		from (  --finds 
		  select distinct tool_id, wm_week, sum(units) as sum_units, sum(sales) as sum_sales
		  from pos_reporting.retail_sales
		  where tool_id::integer in 
							(/*Certian promo items. 
							Ran select distinct tool id from promo type*/
							select tool_id::integer 
							from temp_tool_ids
							)
		  and wm_week in (select distinct wm_date::integer -100 as wm_date
		  				 from wm_calendar w
		  				 where  w.wm_year::integer = 2022
		  				 order by wm_date desc
		  				 limit 13
		  				 )
		  group by tool_id, wm_week
		  	) t1
		  where sum_units >0 
		  --have to omit 0 units after they've been summed 
		  group by tool_id, wm_week
		  
	
		) sum_units
		group by tool_id

	) l13_2020
on pf.tool_id = l13_2020.tool_id::integer

left join (select distinct item_id, product_name from retail_link_pos) pname
on pf.tool_id = pname.item_id
where 1=1
--and aur_2021  >= promo_aur +5
--and l13_2021.tool_id::integer in 
--	(select tool_id 
--	from pos_reporting.promo_funding_item_review pf 
--	where ((pf.promo_units - (pf.promo_week_count * (pf.ly_units/pf.ly_week_count))))/(pf.promo_week_count * (pf.ly_units/pf.ly_week_count) < 0
--	)

;	
/*Step 4. take the same query as step 1 but apply the lift logic
	-Add the deviances to the Last years data to tune the aws
	-Deviances are added on a weekly level, not on a aws per aur level*/
	
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
				select * 
				from pos_reporting.promo_funding_sales
				where 1=1 
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
		select tool_id
			,sum(sum_units) as sum_units
			, sum(sum_sales) as sum_sales
		from (  --sub query to get aur 
		 select tool_id
		 	,wm_week
		 	,promo_aur
		 	,case when sum_units != 0 
		 		then
			 		case when sum_sales/sum_units > promo_aur + 5
			 			then sum_units * (1+ l13_2021_over_2020)
			 			else sum_units
			 			end 
		 		else 0 
		 		end as sum_units
		 	,case when sum_units !=0
		 		then
		 			case when sum_sales/sum_units > promo_aur + 5
		 				then sum_sales * (1+l13_2021_over_2020)
		 				else sum_sales
		 				end
		 		else 0 
		 		end as sum_sales
		 from
			  (
				  --get item id, week, and sum of sales and units for that week
				  select distinct 
				  	  r.tool_id
				  	, wm_week
				  	,coalesce(d.l13_2021_over_2020,0) as l13_2021_over_2020
				  	,coalesce(d.promo_aur,0) as promo_aur
				  	, sum(units) as sum_units
				  	, sum(sales) as sum_sales
				  	--,sum(sales)/sum(units) as aur_2021
				  	--apply deviance from promo aur here
				  from pos_reporting.retail_sales r
				  left join pos_reporting.aur_deviance d
				  on r.tool_id::integer = d.tool_id
				  where r.tool_id::integer in 
									(/*Certian promo items. 
									Ran select distinct tool id from promo type*/
									select tool_id::integer 
									from temp_tool_ids
									)
				  and wm_week >=202201 and wm_week <=202252
				  group by r.tool_id
				  	, wm_week
				  	,d.l13_2021_over_2020
				  	,d.promo_aur
			    ) sales_by_week_2021
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
where 1=1
--and division in ('Ameriwood', 'Dorel Asia','Dorel Home Products')


;	 