--this query creates the following view
--similar to scrape_prices.sql
--exact code but modified with self join and turned into fact table
--it seperate table into recent and early dates/retails to calculate over %
-- lets us compare items that are NOT on promo that have significant retail changes
create view scrape_data.price_compare as (
with fact as (
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
				, t2.date_inserted early_date
				, t1.price_retail as recent_retail
				, t2.price_retail as early_retail
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
		where final_row_num =1		
	)
	,costs as 
		(
		select * 
		from lookups.current_cost
		)
select distinct fact.item_id
	,recent_date
	,early_date
	,recent_retail
	,early_retail
	,recent_over_early_retail
	,on_promo_bool
	,current_dsv_cost
from fact
left join costs
ON fact.model_name = costs.model
);
		
/*START PRICE COMPARE PBIX*/
create or replace view power_bi.price_compare_pbix as (
with fact as (
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
				, t2.date_inserted early_date
				, t1.price_retail as recent_retail
				, t2.price_retail as early_retail
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
		where final_row_num =1		
	)
	,g as (select * 
			from power_bi.group_id_view
		)
	,d as (
		select * 
		from power_bi.divisions_view
		)
	,cbm as (
		select * 
		from cat_by_model
			)
	,pn as 
		(
		select * 
		from power_bi.product_name_view_pbix
		)
	,t as 
		(
		select * 
		from power_bi.tool_id_view
		)
	,b as 
		(
		select * 
		from power_bi.tool_id_view
		)
	,costs as 
		(
		select * 
		from lookups.current_cost
		)
select t.tool_id_id
	,b.tool_id_id as base_id_id
	,cbm.cbm_id
	,d.division_id
	,pn.product_name_id
	,g.group_id_id
	,recent_date
	,early_date
	,recent_retail
	,early_retail
	,recent_over_early_retail
	,on_promo_bool
	,current_dsv_cost
from fact
left join g
on fact.item_id = g.tool_id
left join d
on fact.division = d.division_name
left join cbm
on fact.model_name = cbm.model
left join pn 
on fact.wm_name = pn.product_name
left join t 
on fact.item_id::text = t.tool_id
left join b 
on fact.base_id::text = b.tool_id
left join costs
on fact.model_name = costs.model
);
/*END PRICE COMPARE PBIX*/


/*START PRICE COMPARE TEXT*/
--This view specifically is for the text message. we do this view + or - a where clause for metric filtering
--in parabola, also used for 90 day rollback tracker
create or replace view scrape_data.price_compare_text as (
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
				,to_char(t1.date_inserted,'yyyy-mm-dd') as recent_date
				,coalesce(to_char( rdf.date_inserted,'yyyy-mm-dd'),to_char( t2.date_inserted,'yyyy-mm-dd')) as early_date
				, t1.price_retail as recent_retail
				, coalesce(rdf.price_retail, t2.price_retail) as early_retail
				,t1.price_retail -coalesce(rdf.price_retail, t2.price_retail) as retail_difference
				,case when coalesce(rdf.price_retail, t2.price_retail) is not null
					then ((t1.price_retail - coalesce(rdf.price_retail, t2.price_retail))/(coalesce(rdf.price_retail,t2.price_retail)))::numeric(10,2) 
					end as recent_over_early_retail
				,coalesce(t1.on_promo_bool, 'No') as on_promo_bool
			from scrape_data.price_change t1
			join scrape_data.price_change t2
			on t1.item_id = t2.item_id
			left join lookups.lookup_tbl l1
			on t1.item_id = l1.item_id
			left join ( -- joining rdf(retail date filter) to colaesce between this and early date
						--finds the price retail that has been scraped the most. round to 10 to narrow down search
						select *
						from (
						select item_id
							,((price_retail *.1) *10)::numeric(10,0)  as price_retail
							,min(date_inserted) as date_inserted
							,count(distinct date_inserted) scraped_at_retail
							,row_number() over (partition by item_id order by count(distinct date_inserted) desc) count_rank
						from scrape_data.scrape_tbl
						group by item_id
							,((price_retail *.1) *10)::numeric(10,0) 
						) t1
						where count_rank = 1

						) rdf
			on t2.item_id = rdf.item_id
			where 1=1
			and (-- row num can be combo of 1&2 or 1&1
					(t1.row_number = 1 and t2.row_number = 2)
				or 
					(t1.row_number = 1 and t2.row_number = 1)
				)
		) t1
		where final_row_num =1
	);
/*END PRICE COMPARE TEXT*/


/*START PRICE CHANGE INSERT  */
--SQL Used in python function after scrape data is uploaded. 
insert into scrape_data.price_change(item_id, price_retail, price_was, date_inserted, row_number,on_pomo_bool)
select item_id
	, price_retail
	, price_was
	, date_inserted
	,row_number 
	,on_promo_bool
from (
	select distinct 
		item_id
		, price_retail
		, price_was
		, date_inserted
		,on_promo_bool
		--row number assigns incramental value of 1 starting off on most recent scrape
		--resent to 1 when there is a new item id
		,row_number() over(partition by item_id order by item_id, date_inserted desc)
	from (
		select -- find where an item's retail changes
			item_id
			, price_retail
			, price_was
			, date_inserted 
			,op.on_promo_bool
			--row number assigns incramental value starting at 1. resets to 1 when an item's retail changes
			,row_number() over(partition by item_id, price_retail order by date_inserted desc)
		from scrape_data.scrape_tbl sc1
		left join power_bi.on_promo op 
		on sc1.item_id = op.tool_id
		where price_retail is not null
		) t1
	where row_number = 1-- only looking for the retail change
	and item_id in (select item_id::integer 
					from lookups.tool_id_numeric
					 )
	order by item_id, date_inserted desc
	)t2
where row_number in (1,2) -- only care about most recent changes for an item id
/*END PRICE CHANGE INSERT */
;
/*START ROLLBACK CHANGE*/
create view scrape_data.rollback_change as (
select item_id
	, price_display_code
	, date_inserted
	,row_number 
	,on_promo_bool
from (
	select distinct 
		item_id
		, price_display_code
		, date_inserted
		,on_promo_bool
		--row number assigns incramental value of 1 starting off on most recent scrape
		--resent to 1 when there is a new item id
		,row_number() over(partition by item_id order by item_id, date_inserted desc)
	from (
		select -- find where an item's retail changes
			item_id
			, price_display_code
			, date_inserted 
			,op.on_promo_bool
			--row number assigns incramental value starting at 1. resets to 1 when an item's retail changes
			,row_number() over(partition by item_id, price_display_code order by date_inserted desc)
		from scrape_data.scrape_tbl sc1
		left join power_bi.on_promo op 
		on sc1.item_id = op.tool_id
		where price_retail is not null
		) t1
	where row_number = 1-- only looking for the retail change
	and item_id in (select item_id::integer 
					from lookups.tool_id_numeric
					 )
	order by item_id, date_inserted desc
	)t2
where row_number in (1,2) -- only care about most recent changes for an item id
);



/*END Rollback Change*/