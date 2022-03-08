create view power_bi.wm_pos_fact as (
with 
	model_tool as (
				select distinct s.model, tool_id, s.division
				from ( --finds the model's most recent ship date
					select model, max(date_shipped) as date_compare 
					from ships_schema.ships
					group by model
					) ship_model
				join ships_schema.ships s  
				on s.model = ship_model.model --compares max ship date to get a model tool id relation 
				where 1=1
				and date_shipped = date_compare
				and retailer = 'Walmart.com'
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
--			--starting case statement for last 4, 13, and 52 weeks 
--			,case  
--				when wm_week in (
--								select distinct wm_week 
--								from misc_views.retail_sales
--								order by wm_week desc
--								limit 4
--								 ) then 1
--				when wm_week in (
--								select distinct wm_week 
--								from misc_views.retail_sales
--								order by wm_week desc
--								limit 13
--								) then 2
--				when wm_week in (
--								select distinct wm_week 
--								from misc_views.retail_sales
--								order by wm_week desc
--								limit 52
--								) then 3
--				else null
--				end as last_week
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

select distinct rs.id, mv.model_id,d.division_id, tv.tool_id_id, pnv.product_name_id, g.group_id_id, c.category_id, scv.sub_cat_id, bid.tool_id_id as base_id_id, wmcal.wmcal_id, bn.brand_id
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
)
;