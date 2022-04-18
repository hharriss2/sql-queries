create  view misc_views.wm_stores_pos as ( 
select t1.id,
    t1.pos_qty,
    t1.pos_sales,
    t1.daily AS sale_date,
    t1.prime_item_nbr,
    w.item_id,
    t1.cat,
    t1.sub_cat,
    t1.division,
    t1.retail_type_id,
    t1.product_name,
    t1.model::text,
    t1.prime_item_nbr AS base_id,
    t1.brand_name
from(
with 
    ssa as 
          (
/*##START SSA ##*/
	select distinct ssa.id
            ,case when recent_item_num.prime_item_num is not null 
            		then recent_item_num.prime_item_num 
            	    else ssa.prime_item_nbr::integer 
            	  end as prime_item_nbr
            ,ssa.prime_item_desc
            ,ssa.item_nbr
            ,ssa.item_flags
            ,ssa.item_desc_1
            ,ssa.upc
            ,ssa.vendor_stk_nbr
            ,ssa.vendor_name
            ,ssa.vendor_nbr
            ,ssa.vendor_sequence_nbr
            ,ssa.wm_week
            ,ssa.daily
            ,ssa.unit_retail
            ,ssa.avg_retail
            ,ssa.pos_qty
            ,ssa.pos_sales
            ,1 as retail_type_id
    from sales_stores_auto ssa
    left JOIN (
 --start most recent item number to description
			select distinct 
						case when dupe_lookup.item_description is not null 
						  		 then dupe_lookup.item_num::integer
								 else all_item_nbrs.prime_item_nbr::integer
								 end as prime_item_num -- eliminates unwanted item numbers and dupes
					,recent_item_desc.prime_item_desc
					 , case when dupe_lookup.item_description is not null
					 			 then dupe_lookup.item_id
					 		when dupe_lookup.item_description is null 
					 			 then model_tool.tool_id
					 		else w.item_id end as tool_id--uses most recent tool id if not then item id
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
					select item_num, item_description, item_id
					from (
						select distinct item_num
									, w.item_description
									, w.item_id
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
			where date_compare = daily
			and prime_item_nbr != '569020027'--the one anomoly for now...
			--end most recent item number to description
			and all_item_nbrs.prime_item_desc not in (
	      		/*START DUPE OMIT*/
	      		--this where clause omits anything the dupe check missed
	      		--it's just a dupe count of the dupe check
	      		select distinct  item_description
				from
				(/*start duplicate lookup*/
						  --because of anomolies we have to reuse sql plus a little extra logic and rejoin.
						  --im sure theres a better way I cannot grasp at the moment...
						select item_num, item_description, item_id
						from (
							select distinct item_num
										, w.item_description
										, w.item_id
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
	--						and item_description not in (select t1.item_description from pos_reporting.lookup_stores t1)
						/*end duplicate lookup */ ) t2
						group by item_description
						having count(item_description) >1
					/*END DUPE OMIT*/
					)
			) recent_item_num
      on recent_item_num.prime_item_desc = ssa.prime_item_desc
      where fineline_description !='DOTCOM ONLY' -- does not pull in .com pos data
            
/*##END SSA ##*/ 
            )
    ,wmc as -- not using wmc at the moment. implimented this in pr
            (
            select item_num, item_id, upc,left(gtin,13) as gtin
            from wm_catalog2
            )
    ,wmcbid as 
            (
            select distinct item_id, upc,left(gtin,13) as gtin
            from wm_catalog2
            )
    ,model_tool as 
            (
                select distinct s.model, tool_id, s.division, date_compare
                from ( --finds the model's most recent ship date
                    select model, max(date_shipped) as date_compare 
                    from ships_schema.ships
                    group by model
                    ) ship_model
                join ships_schema.ships s  
                on s.model = ship_model.model --compares max ship date to get a model tool id relation 
                where 1=1
                and date_shipped = date_compare
                --and tool_id is not null /*from og tool id to model formula. it will not give all of the distinct models for upc if added in*/
                and s.retailer in ('Walmart.com','Walmart Stores')
                and tool_id !='0'
            )
    ,d as
            (
            select * 
            from power_bi.divisions_view
            )
    , cbm as 
            (
            select * 
            from cat_by_model 
            )
    , tv as 
            (
            select * 
            from power_bi.tool_id_view
            )
    , pr as (
/*START PR*/
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
            )
    ,pnv as (
            select * 
            from power_bi.product_name_view_pbix
            )
    ,rs as 
            (
            select distinct rs1.tool_id
            , tool_brand.brand_name
            ,upc
            ,r3.base_upc
            from pos_reporting.retail_sales rs1
            left join -- logic to find most recent tool_id to brand 
            (
                select r2.tool_id, brand_name 
                from 
                    (
                    select distinct tool_id, brand_name, max(sale_date) as date_compare
                    from pos_reporting.retail_sales
                    where brand_name is not null
                    group by tool_id, brand_name
                    ) r1 -- r1 finds the max date the brand name and item were sold together
                    right join (
                        select tool_id, max(sale_date) as date_compare 
                        from pos_reporting.retail_sales r2
                        where brand_name is not null
                        group by tool_id
                     ) r2 --r2 finds the max sale date of that item where the brand name is not null
                    on r1.tool_id = r2.tool_id -- join items on iem id 
                    where r1.date_compare = r2.date_compare --set conditional to take max date item was shipped (r2 item_id) 
            ) tool_brand
             on tool_brand.tool_id= rs1.tool_id
            left join -- finds max tool id base upc combo. use this r3 base upc as default upc for rs 
                    (
                    select distinct tool_id, base_upc
                    from
                        (
                        select t1.tool_id, base_upc
                        from
                            (
                            select tool_id, max(sale_date)  as date_compare--find max date tool is is sold
                            from pos_reporting.retail_sales
                            group by tool_id
                            ) t1
                        join pos_reporting.retail_sales t2
                        on t1.tool_id = t2.tool_id 
                        where t1.date_compare = t2.sale_date
                        ) tool_base-- a table for getting most recent tool id base id 
                    ) r3
                    on r3.tool_id = rs1.tool_id
             
            )
    ,c as 
            (
            select * 
            from power_bi.category_view
            )
    ,scv as 
            (
            select * 
            from power_bi.sub_category_view
            )
    ,bid as 
            (
            select * 
            from power_bi.tool_id_view
            )
    ,wmcal as 
            (
            select * 
            from power_bi.wm_calendar_view
            )
    ,bn as (
            select * 
            from power_bi.brand_name
            )
    , rt as (
            select * 
            from power_bi.retail_type
            )
    , g as 
            (
            select * 
            from power_bi.group_id_view
            )
    , mv as 
            (
            select * 
            from power_bi.model_view_pbix
            )
    ,rsbid as 
            (
            select distinct upc, base_upc, tool_id 
            from pos_reporting.retail_sales
            where upc = base_upc
            )
     ,sl as (
            select * 
            from pos_reporting.lookup_stores 
            )
select  distinct ssa.id
--      ,mv.model_name
--      ,mv.model_id
--      ,d.division_id
--      ,tv.tool_id_id
--      ,tv.tool_id
--      ,pnv.product_name_id
--      ,g.group_id_id
--      ,c.category_id
--      ,bid.tool_id_id as base_id_id
--      ,wmcal.wmcal_id, bn.brand_id
--      ,rt.retail_type_id
        ,pos_qty
        ,ssa.pos_sales
        ,ssa.daily
        ,ssa.prime_item_nbr
--      ,wmc.item_num
        --temporary columns--
        ,pr.item_id
        ,cbm.cat
        ,cbm.sub_cat
        ,pr.division
        ,ssa.retail_type_id
        ,CASE
                WHEN pr.product_name IS NOT NULL THEN pr.product_name
                ELSE ssa.prime_item_desc
        END AS product_name
        /*start store lookup heirarchy. in case of no brand/model link or needing to prioritize a model/ brand, store lookup table is used.*/
        ,CASE
                WHEN sl.model IS NOT NULL THEN sl.model
                ELSE pr.model
        END AS model
        ,CASE
                WHEN sl.brand_name IS NOT NULL THEN sl.brand_name
                ELSE rs.brand_name
        END AS brand_name
from ssa 
/*left join wmc on ssa.prime_item_nbr = wmc.item_num::text -- gets item id based off item numbers from store to 360*/
left join pr on ssa.prime_item_nbr = pr.item_num--::text -- switching out wmc to ssa 
--left join pr on wmc.upc = pr.upc -- gets upc with 360 data. joins pims data 
--left join model_tool on model_tool.model = pr.model -- joins model to ships models to get division
--left join cbm on model_tool.model = cbm.model -- gets category 
left join cbm on cbm.model = pr.model
--left join rs on tv.tool_id = rs.tool_id
left join rs on pr.item_id = rs.tool_id
left join wmcbid on wmcbid.gtin = rs.base_upc 
left join bid on bid.tool_id = wmcbid.item_id
left join bn on bn.brand_name = rs.brand_name
left join sl on sl.prime_item_num = ssa.prime_item_nbr
--left join tv on tv.tool_id = pr.item_id-- tool id dim
--left join g on g.tool_id::text = tv.tool_id-- group id dim
--left join c on c.category_name = cbm.cat-- gets cat dim
--left join scv on cbm.sub_cat = scv.sub_cat_name-- gets sub cat dim
--left join wmcal on wmcal.date = ssa.daily-- gets calendar dim
----left join d on model_tool.division = d.division_name --division dim
--left join d on pr.division = d.division_name --get division dim other way
--left join rt on rt.retail_type_id = ssa.retail_type_id -- gets retail type dim
--left join mv on mv.model_name = pr.model-- gets model dim
--left join pnv on pnv.product_name = pr.product_name -- gets product name dim
) t1
left join wm_catalog2 w
on t1.prime_item_nbr = w.item_num)
;
create view power_bi.wm_stores_pos_fact as (
with 
    ssa as 
            (
				select * 
				from misc_views.wm_stores_pos
            )
    ,d as
            (
            select * 
            from power_bi.divisions_view
            )
    , tv as 
            (
            select * 
            from power_bi.tool_id_view
            )
    ,pnv as (
            select * 
            from power_bi.product_name_view_pbix
            )
    ,c as 
            (
            select * 
            from power_bi.category_view
            )
    ,scv as 
            (
            select * 
            from power_bi.sub_category_view
            )
    ,bid as 
            (
            select * 
            from power_bi.tool_id_view
            )
    ,wmcal as 
            (
            select * 
            from power_bi.wm_calendar_view
            )
    ,bn as (
            select * 
            from power_bi.brand_name
            )
    , rt as (
            select * 
            from power_bi.retail_type
            )
    , g as 
            (
            select * 
            from power_bi.group_id_view
            )
    , mv as 
            (
            select * 
            from power_bi.model_view_pbix
            )
select ssa.id
, ssa.pos_qty
, ssa.pos_sales
, wmcal.wmcal_id
, tv.tool_id_id
, c.category_id
,ssa.cat
, scv.sub_cat_id
,d.division_id
, rt.retail_type_id
, pnv.product_name_id
, mv.model_id
from ssa
left join tv on tv.tool_id = ssa.item_id-- tool id dim
left join g on g.tool_id::text = tv.tool_id-- group id dim
left join c on c.category_name = ssa.cat-- gets cat dim
left join scv on scv.sub_cat_name = ssa.sub_cat-- gets sub cat dim
left join wmcal on wmcal.date = ssa.sale_date-- gets calendar dim
--left join d on model_tool.division = d.division_name --division dim
left join d on d.division_name= ssa.division --get division dim other way
left join rt on ssa.retail_type_id = rt.retail_type_id -- gets retail type dim
left join mv on mv.model_name = ssa.model-- gets model dim
left join pnv on pnv.product_name = ssa.product_name -- gets product name dim
)
;

