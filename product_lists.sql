/*com_product_list*/
/*START MODEL_TOOL*/
with pr as (
				/*START PR*/
	select distinct 
	--              , w.item_id
					/*1. use model tool
					, 2. use item id*/
	                 coalesce(rs.item_id::text,case when model_tool.tool_id = '' then w.item_id 
	                 when w.upc != model_tool.upc then w.item_id
	                 when model_tool.tool_id is not null then model_tool.tool_id 
	                 else w.item_id end ) as item_id
	--                 ,rs.item_id::text as tool_id
	                /*1. use shipped model
	                  2. use recent .com model
	                , 3. use recent model tool
	                , 4. use whatever .com model
	                , 5. use whatever model you can find from ships*/
	                ,coalesce(ships_model,case when model_tool.model = pr_com.model then model_tool.model
	                	 when model_tool.tool_id = '' then pr_com.model
	                	 when model_tool.model is not null then model_tool.model
	                	 when model_tool.model is null then pr_com.model else p.model end, p.model) as model
	
--	                ,p.product_name
	                , p.division
	                ,model_tool.date_compare
	--                ,p.model as test_model
	--                ,model_tool.model as model_tool_model
	--                ,pr_com.model as pr_com_model
--	                ,model_tool.tool_id as model_tool_tool_id
	--                ,ships_model as s_model
	--                ,w.item_id as w_item_id
	--                ,w.w_2_item_id
	--                ,w.s_upc as s_upc
	--                ,w.w_upc as w_upc
	--                ,p.upc as p_upc
	--                ,prcom.upc as prcom_upc
	--                ,model_tool.upc as model_tool_upc
--	                ,
--	                        case --case statement chooses upc over base_upc unless upc is missing. 
--	                        -- wm most likely will have white label upc on item360 so it tried pairing white lables first, then base
--	                        When w.upc is not null then w.upc
--	                        when w.upc is null then p.upc
--	                        when p.upc is null then p.base_upc
--	                        when p.base_upc is null then prcom.upc
--	                        when prcom.upc is null then prcom.base_upc 
--	                        else w.upc end as upc
	            from products_raw p 
	            left join  (
	            			--start w
	                        select distinct w.item_id as item_id
	                        				,w2.item_id as w_2_item_id
	                        				, s.upc as s_upc
	                        				,w.upc as w_upc
	                        				,coalesce(s.upc, w.upc) as upc
	--                        				, item_num
											,s.model as ships_model
	                        from wm_catalog2 w
	                        left join 
	                        		(--start s
	/*pretty proud of this ships logic. it takes into account most recent model, upc, and tool ID dates. 
	 - It solves an old item needing new UPC. Ex the following item sells under multiple item id's, both which are current. 
	    - 14715BLK4E has an updated tool id for ships but pos data still uses the old item id (38583600 pos, 587213848 ships) 
	    - 14715BLK4E has 1 upc found in products_raw, 2 upc found in wm catalog.
	    - Solution: give the old item_id the newest upc for linkage.
	 - Solves an item getting a new item id or selling under the wrong item id
	 	- Item ID 13275167 is silver( model 5434096), but has sold under black(5434196W) before.
	 	- Solution: CASE statement. If newest UPC = ships UPC, give it the newest tool id, if not give it the original tool id
	 	  - 14715BLK4E new upc != ships upc so it gets a record with both 38583600 and 587213848 id's since pos has historicals of 38583600
	 	  - 5434196W on the other hand has matching upcs and forgets its relation with 13275167
	 	- No matter what it takes the most recent upc. Old upc's might not show up in products_raw
	 - Solves models with the same upc 
	 	- WM2906W-DC & WM2906WJYF-DC share the same upc,however ships_model it prioritized
	                        		  */
	                        		  --start s
		                        		select distinct 
		                        		s.model
		                        		,case when model_upc.tool_id = '' then s.tool_id
		                        		      when model_upc.upc = s.upc then model_upc.tool_id 
		                        			  else s.tool_id end as tool_id
		                        		,model_upc.upc
	--	                        		 ,s.model
	--	                        		 ,s.tool_id as s_tool_id
	--	                        		 ,model_upc.tool_id as model_upc_tool_id
	--	                        		 ,model_upc.upc as model_upc_upc
	--	                        		 ,s.upc as s_upc
	--	                        		 ,date_compare
	--	                        		finding tool_id to upc combo to better link wm item id with the correct upc
		                        		from ships_schema.ships s 
		                        		join (
			                        			 select s.model, s.upc,s.tool_id, max(date_shipped) as date_compare 
			                        			 from ships_schema.ships s
			                        			 join (
					                        			 select model, max(date_shipped) date_compare2
					                        			 from ships_schema.ships 
					                        			 where 1=1
					                        			 and retailer in ('Walmart.com', 'Walmart Stores')
					                        			 group by model
			                        			 	   ) max_model
			                        			 on s.model = max_model.model
			                        			 join (
			                        			 		select tool_id, max(date_shipped) as date_compare3
			                        			 		from ships_schema.ships
			                        			 		group by tool_id
			                        			 		)max_tool_id
			                        			 on s.tool_id = max_tool_id.tool_id
			                        			 where  1=1
			                        			 and upc like '0%'
			                        			 and date_compare2 = s.date_shipped
			                        			 and date_compare3 = date_compare2
			                        			 and retailer in ('Walmart.com', 'Walmart Stores')
	--		                        			 and s.tool_id = '13275167'
			--                        			 and tool_id is not null
			--									 and s.model ='6228013COM'
			                        			 group by s.model, upc, s.tool_id
		                        			 ) model_upc
		
		                        		on s.model = model_upc.model
		                        		where 1=1
		--                        		and s.date_shipped = model_upc.date_compare
		                        		and retailer in ('Walmart.com', 'Walmart Stores')
		                        		and s.upc like '0%'
	--	                        		and s.tool_id = '35031861'
	--	                        		and s.upc in ('065857166972','065857166989')
		--								select distinct s.tool_id, upc
		--                        		/*finding tool_id to upc combo to better link wm item id with the correct upc*/
		--                        		from ships_schema.ships s 
		--                        		where 1=1
		--                        		and retailer in ('Walmart.com', 'Walmart Stores')
		--                        		and s.upc like '0%'
									--end s
	                        		) s
	                        on w.item_id = s.tool_id
	                        left join wm_catalog2 w2
	                        on w2.upc = s.upc
	--                        coalesce(w.item_id = s.tool_id, w.upc = s.upc)
	--                        where s.model in ('DA7201-BG','DA7201-GR','14715BLK4E')
	                    	--end w
	                        ) w--matches most recent tool id's to walmart item id's 
	            on p.upc = w.upc
	            -- case when p.upc = w.upc then p.upc = w.upc else p.base_upc = w.upc end
	            left join (
	                       select model, upc, base_upc
	                       from products_raw
	                       where retailer_id = 4
	                       ) prcom
	            on p.model = prcom.model
	            left join (
				  /*start model tool*/     
			                select distinct s.model
			                				, case when s.tool_id = '' 
			                				  then old_tool.tool_id 
			                				  else s.tool_id end as tool_id
			                				, s.division
			                				,coalesce(w.upc, s.upc) as upc
			                				, date_compare
			                from ( --finds the model's most recent ship date
			                    select model, max(date_shipped) as date_compare 
			                    from ships_schema.ships
			                    where 1=1
			                    and retailer in ('Walmart.com','Walmart Stores')
			                    group by model
			                    ) ship_model
			                join ships_schema.ships s
			                on s.model = ship_model.model --compares max ship date to get a model tool id relation
			                join ( -- sub query finds model and tool without a negative
			                	 --start old tool 
			                	   select distinct s.model, s.tool_id
			                	   from ships_schema.ships s 
			                	   join (
					                	   select distinct model, max(date_shipped) date_compare
					                	   from ships_schema.ships
					                	   where 1=1
					                	   and retailer in ('Walmart.com','Walmart Stores')
					                	   and tool_id !=''
					                	   and tool_id !='0'
					                	   group by model
				                	   ) model_tool_older
				                	on s.model = model_tool_older.model 
				                	where 1=1 
				                	and date_shipped = date_compare
				                	and tool_id !='0'
				                	and tool_id !=''
				                --end old tool
			                	 )old_tool 
			                on s.model = old_tool.model
			                left join (select item_id,upc from wm_catalog2) w 
			                on s.tool_id = w.item_id
			                where 1=1
			                and date_shipped = date_compare
			                --and tool_id is not null /*from og tool id to model formula. it will not give all of the distinct models for upc if added in*/
			                and s.retailer in ('Walmart.com','Walmart Stores')
			                and s.tool_id !='0'
	--		                and s.model in ('DA6364C-MWC','DA6364GR-MWC')
			           /*end model tool*/      
	            		  ) model_tool
	            on model_tool.model = p.model
	            left join 
	            		(
	            		select distinct model, upc
	            		from products_raw
	            		where retailer_id = 4
	            		) pr_com
	            on p.upc = pr_com.upc
	            left join retail_link_pos rs
	            on w.item_id = rs.item_id::text
	            where 1=1
	            and p.retailer_id in (1,4) --only takes into account walmart items                    
	            and p.model not like '%OLD%' -- pims has OLD as their naming convention for obsolete model numbers
	            and p.product_name not like '%Displ%'
	/*END PR*/
)
,count_pr as (
		select count(item_id), item_id
		from
		(
				/*START PR*/
	select distinct 
	--              , w.item_id
					/*1. use model tool
					, 2. use item id*/
	                 coalesce(rs.item_id::text,case when model_tool.tool_id = '' then w.item_id 
	                 when w.upc != model_tool.upc then w.item_id
	                 when model_tool.tool_id is not null then model_tool.tool_id 
	                 else w.item_id end ) as item_id
	--                 ,rs.item_id::text as tool_id
	                /*1. use shipped model
	                  2. use recent .com model
	                , 3. use recent model tool
	                , 4. use whatever .com model
	                , 5. use whatever model you can find from ships*/
	                ,coalesce(ships_model,case when model_tool.model = pr_com.model then model_tool.model
	                	 when model_tool.tool_id = '' then pr_com.model
	                	 when model_tool.model is not null then model_tool.model
	                	 when model_tool.model is null then pr_com.model else p.model end, p.model) as model
	
--	                ,p.product_name
	                , p.division
	                ,model_tool.date_compare
	--                ,p.model as test_model
	--                ,model_tool.model as model_tool_model
	--                ,pr_com.model as pr_com_model
--	                ,model_tool.tool_id as model_tool_tool_id
	--                ,ships_model as s_model
	--                ,w.item_id as w_item_id
	--                ,w.w_2_item_id
	--                ,w.s_upc as s_upc
	--                ,w.w_upc as w_upc
	--                ,p.upc as p_upc
	--                ,prcom.upc as prcom_upc
	--                ,model_tool.upc as model_tool_upc
--	                ,
--	                        case --case statement chooses upc over base_upc unless upc is missing. 
--	                        -- wm most likely will have white label upc on item360 so it tried pairing white lables first, then base
--	                        When w.upc is not null then w.upc
--	                        when w.upc is null then p.upc
--	                        when p.upc is null then p.base_upc
--	                        when p.base_upc is null then prcom.upc
--	                        when prcom.upc is null then prcom.base_upc 
--	                        else w.upc end as upc
	            from products_raw p 
	            left join  (
	            			--start w
	                        select distinct w.item_id as item_id
	                        				,w2.item_id as w_2_item_id
	                        				, s.upc as s_upc
	                        				,w.upc as w_upc
	                        				,coalesce(s.upc, w.upc) as upc
	--                        				, item_num
											,s.model as ships_model
	                        from wm_catalog2 w
	                        left join 
	                        		(--start s
	/*pretty proud of this ships logic. it takes into account most recent model, upc, and tool ID dates. 
	 - It solves an old item needing new UPC. Ex the following item sells under multiple item id's, both which are current. 
	    - 14715BLK4E has an updated tool id for ships but pos data still uses the old item id (38583600 pos, 587213848 ships) 
	    - 14715BLK4E has 1 upc found in products_raw, 2 upc found in wm catalog.
	    - Solution: give the old item_id the newest upc for linkage.
	 - Solves an item getting a new item id or selling under the wrong item id
	 	- Item ID 13275167 is silver( model 5434096), but has sold under black(5434196W) before.
	 	- Solution: CASE statement. If newest UPC = ships UPC, give it the newest tool id, if not give it the original tool id
	 	  - 14715BLK4E new upc != ships upc so it gets a record with both 38583600 and 587213848 id's since pos has historicals of 38583600
	 	  - 5434196W on the other hand has matching upcs and forgets its relation with 13275167
	 	- No matter what it takes the most recent upc. Old upc's might not show up in products_raw
	 - Solves models with the same upc 
	 	- WM2906W-DC & WM2906WJYF-DC share the same upc,however ships_model it prioritized
	                        		  */
	                        		  --start s
		                        		select distinct 
		                        		s.model
		                        		,case when model_upc.tool_id = '' then s.tool_id
		                        		      when model_upc.upc = s.upc then model_upc.tool_id 
		                        			  else s.tool_id end as tool_id
		                        		,model_upc.upc
	--	                        		 ,s.model
	--	                        		 ,s.tool_id as s_tool_id
	--	                        		 ,model_upc.tool_id as model_upc_tool_id
	--	                        		 ,model_upc.upc as model_upc_upc
	--	                        		 ,s.upc as s_upc
	--	                        		 ,date_compare
	--	                        		finding tool_id to upc combo to better link wm item id with the correct upc
		                        		from ships_schema.ships s 
		                        		join (
			                        			 select s.model, s.upc,s.tool_id, max(date_shipped) as date_compare 
			                        			 from ships_schema.ships s
			                        			 join (
					                        			 select model, max(date_shipped) date_compare2
					                        			 from ships_schema.ships 
					                        			 where 1=1
					                        			 and retailer in ('Walmart.com', 'Walmart Stores')
					                        			 group by model
			                        			 	   ) max_model
			                        			 on s.model = max_model.model
			                        			 join (
			                        			 		select tool_id, max(date_shipped) as date_compare3
			                        			 		from ships_schema.ships
			                        			 		group by tool_id
			                        			 		)max_tool_id
			                        			 on s.tool_id = max_tool_id.tool_id
			                        			 where  1=1
			                        			 and upc like '0%'
			                        			 and date_compare2 = s.date_shipped
			                        			 and date_compare3 = date_compare2
			                        			 and retailer in ('Walmart.com', 'Walmart Stores')
	--		                        			 and s.tool_id = '13275167'
			--                        			 and tool_id is not null
			--									 and s.model ='6228013COM'
			                        			 group by s.model, upc, s.tool_id
		                        			 ) model_upc
		
		                        		on s.model = model_upc.model
		                        		where 1=1
		--                        		and s.date_shipped = model_upc.date_compare
		                        		and retailer in ('Walmart.com', 'Walmart Stores')
		                        		and s.upc like '0%'
	--	                        		and s.tool_id = '35031861'
	--	                        		and s.upc in ('065857166972','065857166989')
		--								select distinct s.tool_id, upc
		--                        		/*finding tool_id to upc combo to better link wm item id with the correct upc*/
		--                        		from ships_schema.ships s 
		--                        		where 1=1
		--                        		and retailer in ('Walmart.com', 'Walmart Stores')
		--                        		and s.upc like '0%'
									--end s
	                        		) s
	                        on w.item_id = s.tool_id
	                        left join wm_catalog2 w2
	                        on w2.upc = s.upc
	--                        coalesce(w.item_id = s.tool_id, w.upc = s.upc)
	--                        where s.model in ('DA7201-BG','DA7201-GR','14715BLK4E')
	                    	--end w
	                        ) w--matches most recent tool id's to walmart item id's 
	            on p.upc = w.upc
	            -- case when p.upc = w.upc then p.upc = w.upc else p.base_upc = w.upc end
	            left join (
	                       select model, upc, base_upc
	                       from products_raw
	                       where retailer_id = 4
	                       ) prcom
	            on p.model = prcom.model
	            left join (
				  /*start model tool*/     
			                select distinct s.model
			                				, case when s.tool_id = '' 
			                				  then old_tool.tool_id 
			                				  else s.tool_id end as tool_id
			                				, s.division
			                				,coalesce(w.upc, s.upc) as upc
			                				, date_compare
			                from ( --finds the model's most recent ship date
			                    select model, max(date_shipped) as date_compare 
			                    from ships_schema.ships
			                    where 1=1
			                    and retailer in ('Walmart.com','Walmart Stores')
			                    group by model
			                    ) ship_model
			                join ships_schema.ships s
			                on s.model = ship_model.model --compares max ship date to get a model tool id relation
			                join ( -- sub query finds model and tool without a negative
			                	 --start old tool 
			                	   select distinct s.model, s.tool_id
			                	   from ships_schema.ships s 
			                	   join (
					                	   select distinct model, max(date_shipped) date_compare
					                	   from ships_schema.ships
					                	   where 1=1
					                	   and retailer in ('Walmart.com','Walmart Stores')
					                	   and tool_id !=''
					                	   and tool_id !='0'
					                	   group by model
				                	   ) model_tool_older
				                	on s.model = model_tool_older.model 
				                	where 1=1 
				                	and date_shipped = date_compare
				                	and tool_id !='0'
				                	and tool_id !=''
				                --end old tool
			                	 )old_tool 
			                on s.model = old_tool.model
			                left join (select item_id,upc from wm_catalog2) w 
			                on s.tool_id = w.item_id
			                where 1=1
			                and date_shipped = date_compare
			                --and tool_id is not null /*from og tool id to model formula. it will not give all of the distinct models for upc if added in*/
			                and s.retailer in ('Walmart.com','Walmart Stores')
			                and s.tool_id !='0'
	--		                and s.model in ('DA6364C-MWC','DA6364GR-MWC')
			           /*end model tool*/      
	            		  ) model_tool
	            on model_tool.model = p.model
	            left join 
	            		(
	            		select distinct model, upc
	            		from products_raw
	            		where retailer_id = 4
	            		) pr_com
	            on p.upc = pr_com.upc
	            left join retail_link_pos rs
	            on w.item_id = rs.item_id::text
	            where 1=1
	            and p.retailer_id in (1,4) --only takes into account walmart items                    
	            and p.model not like '%OLD%' -- pims has OLD as their naming convention for obsolete model numbers
	            and p.product_name not like '%Displ%'
	/*END PR*/
    ) t1
	group by item_id
	having count(item_id) >1

)
		    SELECT pr.item_id,
            pr.model,
            pr.division,
            pr.date_compare
           FROM pr
          WHERE NOT (pr.item_id IN ( SELECT DISTINCT count_pr.item_id
                   FROM count_pr))

/*END MODEL_TOOL*/
/*end com_product_list*/

/*stores_product_list*/
/*Query is used as a version of passport product data */
with p as 
	(
	select upc, product_name, model, wl_model, base_upc, division, retailer_id
	from products_raw
	where 1=1
	and (
	  model in
            (
                select distinct s.model
                from ( --finds the model's most recent ship date
                    select upc, max(date_shipped) as date_compare 
                    from ships_schema.ships
                    group by upc
                    ) ship_model
                join ships_schema.ships s  
                on s.upc = ship_model.upc --compares max ship date to get a model tool id relation 
                where 1=1
                and date_shipped = date_compare
                and s.retailer in ('Walmart.com','Walmart Stores')
            ) -- only including models that have been shipped. 
    or model in
            (
                select distinct w.supplier_stock_id
                from wm_catalog2 w
                where supplier_stock_id not in ('WM3921E','WM2906WJYF-DC')
                /*WM3921E,5997015WCOM,5997303WCOM,WM6940BL,WM6940W*/
                /*BANDAID FIX FOR THE DUPLICATING MODELS IN THIS*/
            )
    )   
                        
	and model not like '%OLD%' -- pims has OLD as their naming convention for obsolete model numbers
	and product_name not like '%Displ%'
 			
	)
,w as 
	( 
	--start w
	--start most recent item num
	select distinct 
				case when dupe_lookup.item_description is not null 
				  		 then dupe_lookup.item_num::integer
						 else all_item_nbrs.prime_item_nbr::integer
						 end as item_num -- eliminates unwanted item numbers and dupes
			,recent_item_desc.prime_item_desc
			 , case when dupe_lookup.item_description is not null
			 			 then dupe_lookup.item_id
			 		when dupe_lookup.item_description is null 
			 			 then model_tool.tool_id
			 		else w.item_id end as item_id--uses most recent tool id if not then item id
			 ,coalesce(dupe_lookup.upc, w.upc) as upc
			 , w.supplier_stock_id
			 
	from 
		(
		select distinct prime_item_desc, max(daily) as date_compare
		from sales_stores_auto
		where fineline_description != 'DOTCOM ONLY'
		group by prime_item_desc
		) recent_item_desc-- gets most recent prime item number with item desc for store pos
	join 
		(
		 select distinct prime_item_nbr, prime_item_desc, daily
		 from sales_stores_auto
		 where fineline_description != 'DOTCOM ONLY'
		 ) all_item_nbrs -- all store pos item numbers to compare
	on recent_item_desc.prime_item_desc = all_item_nbrs.prime_item_desc
	left join wm_catalog2 w -- wm catalog to find most recent tool id's to then find most recent item num
	on w.item_num = prime_item_nbr::integer 
	left join 
		(
            select distinct s.model, tool_id
            from ( --finds the model's most recent ship date
                select model, max(date_shipped) as date_compare 
                from ships_schema.ships
                group by model
                ) ship_model
            join ships_schema.ships s  
            on s.model = ship_model.model --compares max ship date to get a model tool id relation 
            where 1=1
            and date_shipped = date_compare
            --and tool_id is not null
             /*from og tool id to model formula. 
            it will not give all of the distinct models for upc if added in*/
            and s.retailer in ('Walmart.com','Walmart Stores')
            and tool_id !='0'
          )model_tool
    on model_tool.tool_id = w.item_id
    left join 
    	( 
			  /*start duplicate lookup*/
			  --because of anomolies we have to reuse sql plus a little extra logic and rejoin.
			  --im sure theres a better way I cannot grasp at the moment...
			select item_num, item_description, item_id, upc
			from (
				select distinct item_num
							, w.item_description
							, w.item_id
							,w.upc
			from wm_catalog2 w
			where item_description in(
			
				--count of duped item desc                   
				select prime_item_desc 
				from (                   
				select distinct prime_item_nbr,recent_item_desc.prime_item_desc
				from 
					(
					select distinct prime_item_desc, max(daily) as date_compare
					from sales_stores_auto
					where fineline_description != 'DOTCOM ONLY'
					group by prime_item_desc
					) recent_item_desc
				join 
					(
					 select distinct prime_item_nbr, prime_item_desc, daily
					 from sales_stores_auto
					 where fineline_description != 'DOTCOM ONLY'
					 ) all_item_nbrs
				on recent_item_desc.prime_item_desc = all_item_nbrs.prime_item_desc
				where date_compare = daily
				) t1
				group by prime_item_desc 
				having count(prime_item_desc) >1
				--end count of duped item desc
					 )
				) dupe_store_records
				where item_id in ( 
							--start where clasue. find's the tool id's for most recent list. 
							select distinct tool_id
			                from ( --finds the model's most recent ship date
			                    select model, max(date_shipped) as date_compare 
			                    from ships_schema.ships
			                    group by model
			                    ) ship_model
			                join ships_schema.ships s  
			                on s.model = ship_model.model 
			                --^^compares max ship date to get a model tool id relation 
			                where 1=1
			                and date_shipped = date_compare
			                --and tool_id is not null
			                 /*from og tool id to model formula. 
			                it will not give all of the distinct models for upc if added in*/
			                and s.retailer in ('Walmart.com','Walmart Stores')
			                and tool_id !='0'
			                -- end where clasue.
									) 
				and item_num !='569020027' --get rid of one anomoly aka MS METAL ARM FUTON
			/*end duplicate lookup */ 
		) dupe_lookup -- lookup view of the dupes the recent_item_desc couldn't figure out 
	on dupe_lookup.item_description = w.item_description
	left join (
							--find's the upc  for most recent list. 
							select distinct tool_id, ship_upc.upc
			                from ( --finds the model's most recent ship date
			                    select upc, max(date_shipped) as date_compare 
			                    from ships_schema.ships
			                    group by upc
			                    ) ship_upc
			                join ships_schema.ships s  
			                on s.upc = ship_upc.upc 
			                --^^compares max ship date to get a model tool id relation 
			                where 1=1
			                and date_shipped = date_compare
			                --and tool_id is not null
			                 /*from og tool id to model formula. 
			                it will not give all of the distinct models for upc if added in*/
			                and s.retailer in ('Walmart.com','Walmart Stores')
			                and tool_id !='0'
			                -- end where clasue.
				) tool_upc
	on coalesce(tool_upc.tool_id = dupe_lookup.item_id,tool_upc.tool_id= model_tool.tool_id, tool_upc.tool_id= w.item_id)
	where date_compare = daily
	and prime_item_nbr != '569020027'--the one anomoly for now...
	--end most recent item num
--end w

	 
	)
,model_tool as 
	(
	select distinct s.model
	, case when s.tool_id = '' 
	  then old_tool.tool_id 
	  else s.tool_id end as tool_id
	, s.division
	,s.upc
	, date_compare
    from ( --finds the model's most recent ship date
        select model, max(date_shipped) as date_compare 
        from ships_schema.ships
        group by model
        ) ship_model
    join ships_schema.ships s
    on s.model = ship_model.model --compares max ship date to get a model tool id relation
    join ( -- sub query finds model and tool without a blank value. 
    	 --start old tool 
    	   select distinct s.model, s.tool_id
    	   from ships_schema.ships s 
    	   join (
            	   select distinct model, max(date_shipped) date_compare
            	   from ships_schema.ships
            	   where 1=1
            	   and retailer in ('Walmart.com','Walmart Stores')
            	   and tool_id !=''
            	   and tool_id !='0'
            	   group by model
        	   ) model_tool_older
        	on s.model = model_tool_older.model 
        	where 1=1 
        	and date_shipped = date_compare
        	and tool_id !='0'
        	and tool_id !=''
        --end old tool
    	 )old_tool 
    on s.model = old_tool.model
    where 1=1
    and date_shipped = date_compare
    --and tool_id is not null /*commented out. from og tool id to model formula. it will not give all of the distinct models for upc if added in*/
    and s.retailer in ('Walmart.com','Walmart Stores')
    and s.tool_id !='0'
	)
,model_upc as 
	(
 select s.model, s.upc, max(date_shipped) as date_compare 
 from ships_schema.ships s
 join (
		 select upc, max(date_shipped) date_compare2
		 from ships_schema.ships 
		 where 1=1
		 and retailer in ('Walmart.com', 'Walmart Stores')
		 group by upc
 	   ) max_model
 on s.upc = max_model.upc
 where  1=1
 and s.upc like '0%'
 and date_compare2 = s.date_shipped
 and retailer in ('Walmart.com', 'Walmart Stores')
-- AND s.upc  = '044681346484'
--		                        			 and s.tool_id = '13275167'
--                        			 and tool_id is not null
--									 and s.model ='6228013COM'
 group by s.model, s.upc
	)

SELECT distinct  item_num
--	              , w.item_id
            ,case when model_tool.tool_id = '' then w.item_id 
             when model_tool.tool_id is not null then model_tool.tool_id 
             else w.item_id end  as item_id
            ,coalesce(model_upc.model,p.model) as model
            ,p.product_name
            , p.division
	                ,p.model as p_model
                ,model_tool.model as model_tool_model
                ,model_tool.tool_id
                ,model_upc.model as upc_model
            ,
            case --case statement chooses upc over base_upc unless upc is missing. 
            /*wm most likely will have white label upc on item360 so it tried pairing white lables first,then base*/
            When w.upc is not null then w.upc
            when w.upc is null then p.upc
            when p.upc is null then p.base_upc end as upc
FROM p left join w 
ON coalesce(p.base_upc = w.upc,p.upc = w.upc, p.model = w.supplier_stock_id)
left join model_tool
on model_tool.model = p.model
left join model_upc
on coalesce(p.base_upc = model_upc.upc, p.upc = model_upc.upc)
where 1=1
and p.retailer_id in (1,4) --only takes into account walmart items
--and p.model = '37127BLK4W'
--and item_num = 578376547
/*#END PR*/
/* end stores_product_list*/