

with 
	model_tool as (
				select distinct s.model, s.tool_id, division
			from ( --finds the model's most recent ship date
					select tool_id, max(date_shipped) as date_compare 
					from ships_schema.ships
					where retailer in ('Walmart.com', 'Walmart Stores')-- filter walmart.com to only find tool id's on .com sales
					and tool_id !=''-- anomoly of having blank tool id 
					group by tool_id
				  ) ship_model
			join ships_schema.ships s  
			on s.tool_id = ship_model.tool_id --compares max ship date to get a model tool id relation 
			where 1=1
			and date_shipped = date_compare
			and s.retailer in ('Walmart.com', 'Walmart Stores')
			and s.tool_id !=''
				)
	,pn as ( 
			 select distinct product_name, model --use this for product name
			 from products_raw
		   )
	,g as (
		   select tool_id::text, group_id, collection_name, group_id_id, concat_gid_name
		   from power_bi.group_id_view --group id's of course
		   )
	,rs as (
			select rs1.id
			, rs1.tool_id
			, product_name
			, upc
			, tool_brand.brand_name
			,base_upc
			, sale_date
			, wm_week
			, units
			, sales
			, 2 as retail_type_id  -- our .com sales
			from misc_views.retail_sales rs1
			left join -- logic to find most recent tool_id to brand 
			(
				select r2.tool_id, brand_name 
				from 
					(
					select distinct tool_id, brand_name, max(sale_date) as date_compare
					from misc_views.retail_sales
					where brand_name is not null
					group by tool_id, brand_name
					) r1 -- r1 finds the max date the brand name and item were sold together
					right join (
						select tool_id, max(sale_date) as date_compare 
						from misc_views.retail_sales r2
						where brand_name is not null
						group by tool_id
						 ) r2 --r2 finds the max sale date of that item where the brand name is not null
					on r1.tool_id = r2.tool_id -- join items on iem id 
					where r1.date_compare = r2.date_compare --set conditional to take max date item was shipped (r2 item_id) 
			) tool_brand
			 on tool_brand.tool_id= rs1.tool_id
			)
	,cbm as (
			select * --link model to category
			from cat_by_model
			)
	,c as (
			select * -- category dim table
			from power_bi.category_view
			)
	,tv as (
			select * --tool_id dim table
			from power_bi.tool_id_view
			)
	,pnv as (
			select *  --product name dim table
			from power_bi.product_name_view_pbix
			)
	,rt as ( 
				select * 
				from power_bi.retail_type
			)
	, wmc as ( select item_num, item_id, left(gtin,13) as gtin, item_description
				from wm_catalog2

			)
	, mv as (
			select * 
			from power_bi.model_view_pbix
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
	,d as (
			select * 
			from power_bi.divisions_view
			)
	,scv as (
			select * 
			from power_bi.sub_category_view
			)
	,bid as (
			select * 
			from power_bi.tool_id_view
			)


select distinct rs.id, mv.model_id,d.division_id, tv.tool_id_id, pnv.product_name_id, g.group_id_id, c.category_id, scv.sub_cat_id, bid.tool_id_id as base_id_id, wmcal.wmcal_id, bn.brand_id,rt.retail_type_id
from rs
left join model_tool on model_tool.tool_id = rs.tool_id -- get model to tool 
left join pn on pn.model = model_tool.model -- get product name
left join g on g.tool_id = rs.tool_id  -- get group id
left join cbm on cbm.model = model_tool.model -- get category
left join c on c.category_name = cbm.cat-- get category id 
left join wmc on  rs.base_upc = wmc.gtin -- get base id 
left join wmcal on wmcal.date = rs.sale_date -- get date id 
left join bn on bn.brand_name = rs.brand_name -- get brand name id 
left join d on d.division_name = model_tool.division -- get division id 
left join mv on mv.model_name = model_tool.model 
left join tv on tv.tool_id = rs.tool_id
left join pnv on pnv.product_name = pn.product_name
left join  scv on scv.sub_cat_name = cbm.sub_cat
left join  bid on wmc.item_id = bid.tool_id
left join rt on rt.retail_type_id = rs.retail_type_id 


;
drop materialized view test_ssa_mat;
create materialized view test_ssa_mat as (

with 
	ssa as 
			(
			select *,1 as retail_type_id
			from sales_stores_auto
			where fineline_description !='DOTCOM ONLY' -- does not pull in .com pos data
			)
	,wmc as 
			(
			select distinct item_num, item_id, upc,left(gtin,13) as gtin
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
			select distinct product_name, model, division,
						case --case statement chooses upc over base_upc unless upc is missing. 
						-- wm most likely will have white label upc on item360 so it tried pairing white lables first, then base
						when upc is null then base_upc 
						else upc end as upc
			from products_raw
			where 1=1
			and retailer_id =1 --only takes into account walmart items
			and model in
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
				and tool_id !='0'
						) -- only including models that have been shipped. 
			and model not like '%OLD%' -- pims has OLD as their naming convention for obsolete model numbers
			and product_name not like '%Displ%'
			
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
			from misc_views.retail_sales rs1
			left join -- logic to find most recent tool_id to brand 
			(
				select r2.tool_id, brand_name 
				from 
					(
					select distinct tool_id, brand_name, max(sale_date) as date_compare
					from misc_views.retail_sales
					where brand_name is not null
					group by tool_id, brand_name
					) r1 -- r1 finds the max date the brand name and item were sold together
					right join (
						select tool_id, max(sale_date) as date_compare 
						from misc_views.retail_sales r2
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
							from misc_views.retail_sales
							group by tool_id
							) t1
						join misc_views.retail_sales t2
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
			from misc_views.retail_sales
			where upc = base_upc
			)
select ssa.id, mv.model_id, mv.model_name, d.division_id, tv.tool_id_id, tv.tool_id,pnv.product_name_id, g.group_id_id, c.category_id, bid.tool_id_id as base_id_id, wmcal.wmcal_id, bn.brand_id, rt.retail_type_id, pos_qty, ssa.pos_sales, ssa.wm_week
from ssa 
left join wmc on ssa.prime_item_nbr = wmc.item_num::text -- gets item id based off item numbers from store to 360
left join pr on wmc.upc = pr.upc -- gets upc with 360 data. joins pims data 
--left join model_tool on model_tool.model = pr.model -- joins model to ships models to get division
--left join d on model_tool.division = d.division_name --division dim
left join d on pr.division = d.division_name --get division dim other way
left join tv on tv.tool_id = wmc.item_id-- tool id dim
left join g on g.tool_id::text = tv.tool_id-- group id dim
--left join cbm on model_tool.model = cbm.model -- gets category 
left join cbm on cbm.model = pr.model
left join c on c.category_name = cbm.cat-- gets cat dim
left join scv on cbm.sub_cat = scv.sub_cat_name-- gets sub cat dim
left join wmcal on wmcal.date = ssa.daily-- gets calendar dim
left join rt on rt.retail_type_id = ssa.retail_type_id -- gets retail type dim
left join mv on mv.model_name = pr.model-- gets model dim
left join pnv on pnv.product_name = pr.product_name -- gets product name dim
left join rs on tv.tool_id = rs.tool_id
left join wmcbid on wmcbid.gtin = rs.base_upc 
left join bid on bid.tool_id = wmcbid.item_id
left join bn on bn.brand_name = rs.brand_name
)
;

select sum(pos_sales) 
from sales_stores_auto
where wm_week = 202201
union all
select sum(pos_sales) 
from test_ssa
where wm_week = 202201;
select * 
from test_ssa
limit 1000;

select model, count(model)
from (
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
				and tool_id is not null
				and s.retailer in ('Walmart.com','Walmart Stores')
		)dupe_check
group by model
having count(model) >1
;
select id, count(id) 
from test_ssa_mat
group by id
having count(id) >1
;

select  distinct dupe_check2.*
from(
select * 
from test_ssa_mat 
where id in
	(
	select id
	from test_ssa_mat
	group by id
	having count(id) >1
	)
and division_id is not null
)dupe_check2
join ships_schema.ships s
on s.model = dupe_check2.model_name
where 1=1
and s.product_name not like ('%Displ%')
--and id = 377891
;
--group by id
--having count(id) >1;

select ssa.*, pr.model
from sales_stores_auto ssa 
left join  wm_catalog2 wmc on ssa.prime_item_nbr = wmc.item_num::text -- gets item id based off item numbers from store to 360
left join products_raw pr on wmc.upc = pr.upc -- gets upc with 360 data. joins pims data 
where id = 457315;

select upc, count(upc) 
from (
select distinct model, upc
from products_raw 
where retailer_id = 1
and model not like '%OLD%'
) dupe_check 
group by upc
having count(upc)>1;

select * 
from products_raw
where 1=1
and upc ='044681346989'
--and model  in('14715BLK4W','14715BLK22')
--and retailer_id = 1
;

select * 
from ships_schema.ships
where model = '14778WSL2W';
select distinct *
from ships_schema.ships 
where 1=1
and model in ('2169259W','2169259WR');

select  product_name, model, division, upc, w_upc, pr_upc, retailer_id_1
--model, count(model)
from
(
select distinct product_name, model, division,
						case --case statement chooses upc over base_upc unless upc is missing. 
						-- wm most likely will have white label upc on item360 so it tried pairing white lables first, then base
						when w.upc is null then p.upc
						when p.upc is null then base_upc 
						else w.upc end as upc, p.upc pr_upc, w.upc w_upc
						, case when retailer_id = 1 then retailer_id end as retailer_id_1
						, case when retailer_id = 4 then retailer_id end as retailer_id_4
			from products_raw p 
			left join  (
						select distinct upc, w.supplier_stock_id
						from wm_catalog2 w
						join 
							(
							select supplier_stock_id, max(site_end_date) as date_compare -- might need to tweak date compare..l
							from wm_catalog2
							group by supplier_stock_id
							) compare_upc
						on w.supplier_stock_id = compare_upc.supplier_stock_id 
						where w.site_end_date = compare_upc.date_compare
						) w-- finds most current upc for supplier stock id
			on p.model = w.supplier_stock_id
			where 1=1
			and retailer_id in(1,4) --only takes into account walmart items
			and (model in
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
						)
				)						
			and model not like '%OLD%' -- pims has OLD as their naming convention for obsolete model numbers
			and product_name not like '%Displ%'
			) t1 
			where model = '12312ABL1E'
--			group by model 
--			having count(model) >1
			;
--0004468131327
--00044681313271
select * 
from test_ssa_mat
order by wm_week desc;

select * 
from model_check 
where upc in (
select upc
from wm_catalog2
where item_id = '734295153');

select * 
from sales_stores_auto
where prime_item_nbr = '553814558';