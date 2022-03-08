with 
	ssa as 
			(
			select *,1 as retail_type_id
			from sales_stores_auto
			)
	,wmc as 
			(
			select distinct item_num, item_id, upc
			from wm_catalog2
			)
	,wmcbid as 
			(
			select distinct item_num, item_id, upc,gtin
			from wm_catalog2
			)
	,model_tool as 
			(
				select distinct model, division
				from ships_schema.ships
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
			select distinct product_name, model,
						case --case statement chooses upc over base_upc unless upc is missing. 
						-- wm most likely will have white label upc on item360 so it tried pairing white lables first, then base
						when upc is null then base_upc 
						else upc end as upc
			from products_raw
			where retailer_id in (1,4) --only takes into account walmart items
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
			,base_upc
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
select ssa.id, mv.model_id, d.division_id, tv.tool_id_id, pnv.product_name_id, g.group_id_id, c.category_id, bid.tool_id_id as base_id_id, wmcal.wmcal_id, bn.brand_id, rt.retail_type_id
from ssa 
left join wmc on ssa.prime_item_nbr = wmc.item_num::text
left join pr on wmc.upc = pr.upc
left join model_tool on model_tool.model = pr.model
left join d on model_tool.division = d.division_name
left join tv on tv.tool_id = wmc.item_id
left join g on g.tool_id::text = tv.tool_id
left join cbm on model_tool.model = cbm.model 
left join c on c.category_name = cbm.cat
left join scv on cbm.sub_cat = scv.sub_cat_name
--left join bid on bid.tool_id = wmc.item_id 
left join wmcal on wmcal.date = ssa.daily
left join rt on rt.retail_type_id = ssa.retail_type_id
left join mv on mv.model_name = pr.model
left join pnv on pnv.product_name = pr.product_name
left join wmcbid on wmcbid.item_id = wmc.item_id
left join rs on  rs.base_upc = wmcbid.gtin
left join bn on bn.brand_name = rs.brand_name
left join bid on bid.tool_id = rs.tool_id
limit 1;

