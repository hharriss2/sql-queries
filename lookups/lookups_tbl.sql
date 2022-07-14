create or replace view lookups.lookup_tbl as (
    --step 1. Find the best suited model in l1
    --step 2. Find the best suited tool id in l2
select distinct model_name
--		,wl_model
		,l1.item_id
		,coalesce(l2.base_id, l1.base_id) as base_id
		,group_id
		,division
		,color
		,cat
		,sub_cat
		,l1.product_name as dorel_name
		,l2.product_name as wm_name
		,collection_name
		,coalesce(l2.brand_name, l1.brand_name) as brand_name
        ,bed_size
        ,wl_model
from
( 
    /*START L1*/
    --compare every model found in the database (minus white lables) and find the most accurate information for them
    --look for it in database first, then use kevins lookup
	with 
		mv as (
				select model_name from model_view
				)
		,ml as (select * 
				from clean_data.master_com_list
				)
		,cbm as (select * 
				from cat_by_model
				)
		,p as (select distinct model, wl_model , product_name, division, color, upc, size
				from products_raw 
			)
		,kl as (select model_name, base_id, product_name, color, store_shared,brand_name, division, tool_id, wl_model_name ,upc, bed_size
				from lookup_products_kev
				)
	select distinct
	 	mv.model_name
	 	,coalesce(p.wl_model, kl.wl_model_name) as wl_model
	 	,coalesce(ml.item_id, kl.tool_id::integer) as item_id
		,coalesce(p.color, kl.color) as color
		,cbm.cat
		,cbm.sub_cat
		,coalesce(p.product_name, kl.product_name) as product_name
		,coalesce(ml.division,p.division, kl.division) as division
		,brand_name
		,base_id
		,coalesce(kl.bed_size,size) as bed_size
	from mv
	left join ml
	on mv.model_name = ml.model
	left join cbm
	on mv.model_name = cbm.model
	left join p
	on p.model = mv.model_name
	left join kl
	on kl.model_name = mv.model_name
	where 1=1
	and mv.model_name not in (select distinct wl_model from products_raw where model != wl_model)
	--and mv.model_name = '566087845'
	--and cat = 'Folding Furniture'
) l1
/*END L1*/
left join 
(/*START L2*/
    --compare every tool ID found in the database (minus non numericals) and find the most accurate information for them
    --we handle this in 2 different tables becasue we don't want to colaesce join on our model then kevins. Seems less efficient
	with 
		tv as (
			  select tool_id::integer, tool_id_id
			  from tool_id_view
			  where tool_id ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'
			  )
		,tbt as
			(select tool_id::integer, brand_name
			from lookups.tool_brand_tbl
			)
		,tpn as 
			(
			select tool_id::integer, product_name
			from lookups.tool_pn_tbl
			)
		,g as 
			(
			select * 
			from group_ids
			)
		,bid as 
			(
			select *
			from lookups.current_base_id
			)	
	select 
		tv.tool_id
		,tbt.brand_name
		,tpn.product_name
		,g.group_id
		,g.collection_name
		,bid.base_id
	from tv
	left join tbt
	on tv.tool_id = tbt.tool_id
	left join tpn
	on tv.tool_id = tpn.tool_id
	left join g
	on tv.tool_id = g.tool_id
	left join bid
	on bid.group_id = g.group_id
) l2
/*END L2*/
on l1.item_id = l2.tool_id
)
;
