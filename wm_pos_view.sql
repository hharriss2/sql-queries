/*this is for wm pos data. the query contains all the links to dim tables but columns are dim columns not fact columns*/
 
 WITH model_tool AS (
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

/*END MODEL_TOOL*/

        ), pn AS (
         SELECT DISTINCT products_raw.product_name,
            products_raw.model
           FROM products_raw
        ), g AS (
         SELECT group_id_view.tool_id::text AS tool_id,
            group_id_view.group_id,
            group_id_view.collection_name,
            group_id_view.group_id_id,
            group_id_view.concat_gid_name
           FROM power_bi.group_id_view
        ), rs AS (
         SELECT rs1.id,
            rs1.tool_id,
            rs1.product_name,
            rs1.upc,
            tool_brand.brand_name,
            rs1.base_upc,
            rs1.sale_date,
            rs1.wm_week,
            rs1.units,
            rs1.sales,
            2 AS retail_type_id
           FROM pos_reporting.retail_sales rs1
             LEFT JOIN ( SELECT r2.tool_id,
                    r1.brand_name
                   FROM ( SELECT DISTINCT retail_sales.tool_id,
                            retail_sales.brand_name,
                            max(retail_sales.sale_date) AS date_compare
                           FROM pos_reporting.retail_sales
                          WHERE retail_sales.brand_name IS NOT NULL
                          GROUP BY retail_sales.tool_id, retail_sales.brand_name) r1
                     RIGHT JOIN ( SELECT r2_1.tool_id,
                            max(r2_1.sale_date) AS date_compare
                           FROM pos_reporting.retail_sales r2_1
                          WHERE r2_1.brand_name IS NOT NULL
                          GROUP BY r2_1.tool_id) r2 ON r1.tool_id = r2.tool_id
                  WHERE r1.date_compare = r2.date_compare) tool_brand ON tool_brand.tool_id = rs1.tool_id
        ), cbm AS (
         SELECT cat_by_model.model,
            cat_by_model.cat,
            cat_by_model.sub_cat,
            cat_by_model.cbm_id
           FROM cat_by_model
        ), c AS (
         SELECT category_view.category_id,
            category_view.category_name,
            category_view.am_id
           FROM power_bi.category_view
        ), tv AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), rt AS (
         SELECT retail_type.retail_type_id,
            retail_type.retail_type
           FROM power_bi.retail_type
        ), wmc AS (
         SELECT wm_catalog2.item_num,
            wm_catalog2.item_id,
            "left"(wm_catalog2.gtin, 13) AS gtin,
            wm_catalog2.item_description
           FROM wm_catalog2
        ), mv AS (
         SELECT model_view_pbix.model_name,
            model_view_pbix.model_id
           FROM power_bi.model_view_pbix
        ), wmcal AS (
         SELECT wm_calendar_view.wmcal_id,
            wm_calendar_view.date,
            wm_calendar_view.wm_week,
            wm_calendar_view.wm_year,
            wm_calendar_view.wm_date,
            wm_calendar_view.month
           FROM power_bi.wm_calendar_view
        ), bn AS (
         SELECT brand_name.brand_id,
            brand_name.brand_name
           FROM power_bi.brand_name
        ), d AS (
         SELECT divisions_view.division_id,
            divisions_view.division_name
           FROM power_bi.divisions_view
        )
        ,lookup as (/*lookup table is to find missing model and item ids for pos. also to omit duplicated done in the case statment for model*/	
			select t1.item_id, model, division, product_name
			from pos_reporting.lookup_com t1
			 join
			(--finding most recent record for an inserted item id
				select item_id, max(date_inserted) as date_compare 
				from pos_reporting.lookup_com
				group by item_id
			) t2
			on t1.item_id = t2.item_id
			and date_inserted = date_compare
		)
 SELECT DISTINCT rs.id,
    coalesce(lookup.model,model_tool.model) as model,
    coalesce(lookup.division,model_tool.division) as division,
    rs.tool_id,
    coalesce(lookup.product_name,pn.product_name, rs.product_name) as product_name,
    g.group_id,
    cbm.cat,
    wmc.item_id AS base_id,
    rs.sale_date,
    rs.wm_week,
    rs.brand_name,
    rs.base_upc,
    rs.units,
    rs.sales
   FROM rs
     LEFT JOIN model_tool ON model_tool.item_id::text = rs.tool_id
     LEFT JOIN pn ON pn.model = model_tool.model::text
     LEFT JOIN g ON g.tool_id = rs.tool_id
     LEFT JOIN cbm ON cbm.model = model_tool.model::text
     LEFT JOIN c ON c.category_name = cbm.cat
     LEFT JOIN wmc ON rs.base_upc = wmc.gtin
     LEFT JOIN wmcal ON wmcal.date = rs.sale_date
     LEFT JOIN bn ON bn.brand_name = rs.brand_name
     LEFT JOIN d ON d.division_name = model_tool.division::text
     LEFT JOIN lookup on lookup.item_id = rs.tool_id

;
