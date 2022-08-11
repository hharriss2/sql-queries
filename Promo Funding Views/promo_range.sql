/*PROMO RANGE QUERY*/
--WARNING: query will cause duplicate records joinng on tool_id and start/end dates. must distinct and leave out PK

--query finds the ranges an item is under promo
--items can have overlaping promos, or start a promo right after they end one
 create or replace view pos_reporting.promo_range as (
	select t1.id
		,tool_id
		,min(start_date)::date as start_date
		,max(end_date)::date as end_date
		--joining in subquery creates duplicates. find the min start and max end date for an id. 
		,'Yes' as promo_bool
	
	from(
		with t1 as (-- t1 and t2 are the same
				select 
					id
					,tool_id
					--start case statements	
						--rounding up promo days to match up with forecast
						--if the promo day starts or ends after the 16th, treat the promo as if it starts next month			
					,case when to_char(start_date,'dd')::integer <'16'
					then to_char(start_date,'yyyy-mm-01') 
					else to_char(start_date + interval '1 month', 'yyyy-mm-01')
					end as start_date
				,case when to_char(end_date,'dd')::integer <'16' 
					then to_char(end_date,'yyyy-mm-01') 
					else to_char(end_date + interval '1 month', 'yyyy-mm-01')
					end as end_date
					--end case statements
			   FROM pos_reporting.promo_funding_clean2
			   		)
			  ,t2 as (
			  		
			  select id
					,tool_id				
					,case when to_char(start_date,'dd')::integer <'16' 
					then to_char(start_date,'yyyy-mm-01') 
					else to_char(start_date + interval '1 month', 'yyyy-mm-01')
					end as start_date
				,case when to_char(end_date,'dd')::integer <'16' 
					then to_char(end_date,'yyyy-mm-01') 
					else to_char(end_date + interval '1 month', 'yyyy-mm-01')
					end as end_date
			   FROM pos_reporting.promo_funding_clean2
	--		   where tool_id = 'DA7501N'
			  		)
		select t1.tool_id
		,t1.id
		,t2.start_date
		,t2.end_date
	   FROM t1
	   --self join to find overlapping promo dates
	   left join  t2 
	   on t1.tool_id = t2.tool_id and ( (t1.start_date <= t2.start_date and t1.end_date >= t2.start_date) or t1.start_date = t2.end_date) 
	   where  1=1 
	
	)t1
group by id
,tool_id
	)
	;