 create or replace view power_bi.wm_stores_pos_fact as 
 (
 WITH ssa AS (
         SELECT wm_stores_pos.id,
            wm_stores_pos.pos_qty,
            wm_stores_pos.pos_sales,
            wm_stores_pos.curr_repl_instock,
            wm_stores_pos.sale_date,
            wm_stores_pos.item_id,
            wm_stores_pos.cbm_id,
            wm_stores_pos.am_id,
            wm_stores_pos.division,
            wm_stores_pos.retail_type_id,
            wm_stores_pos.product_name,
            wm_stores_pos.model,
            wm_stores_pos.base_id,
            wm_stores_pos.brand_name,
            wm_stores_pos.item_stat_id
           FROM pos_reporting.wm_stores_pos
        )
,wc_ty as -- week count
	(--starts from full week of sales and ranks going down the 52 weeks
	--used to figure out l4,l13, and l52 weeks
	select distinct wm_date
		,dense_rank() over (order by wm_date desc) as wc_id
	from power_bi.wm_calendar_view t1
	where t1.date <=(now()::date) - interval '1 week'
	order by wm_date desc
	limit 52
	)
,wc_ly as 
(
	select distinct wm_date
		,dense_rank() over (order by wm_date desc) as wc_id
	from power_bi.wm_calendar_view t1
	where t1.date <=(now()::date - interval '1 year') - interval '1 week'
	order by wm_date desc
	limit 52
)
,wmcal AS 
(
	 SELECT wcv.wmcal_id,
	wcv.date,
	wcv.wm_week,
	wcv.wm_year,
	wcv.wm_date,
	wcv.month,
	wc_ty.wc_id as wc_id_ty,
	wc_ly.wc_id as wc_id_ly
	FROM power_bi.wm_calendar_view wcv
	left join wc_ty
	on wcv.wm_date = wc_ty.wm_date
	left join wc_ly
	on wcv.wm_date = wc_ly.wm_date
	)
        , d AS (
         SELECT divisions_view.division_id,
            divisions_view.division_name
           FROM power_bi.divisions_view
        ), tv AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), pnv AS (
         SELECT product_name_view_pbix.product_name,
            product_name_view_pbix.product_name_id
           FROM power_bi.product_name_view_pbix
        ), bid AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), bn AS (
         SELECT brand_name.brand_id,
            brand_name.brand_name
           FROM power_bi.brand_name
        ), rt AS (
         SELECT retail_type.retail_type_id,
            retail_type.retail_type
           FROM power_bi.retail_type
        ), g AS (
         SELECT group_id_view.tool_id,
            group_id_view.group_id,
            group_id_view.collection_name,
            group_id_view.group_id_id,
            group_id_view.concat_gid_name,
            group_id_view.in_production
           FROM power_bi.group_id_view
        ), mv AS (
         SELECT model_view_pbix.model_name,
            model_view_pbix.model_id
           FROM power_bi.model_view_pbix
        )
 SELECT ssa.id,
    ssa.pos_qty,
    ssa.pos_sales,
    wmcal.wmcal_id,
    tv.tool_id_id,
    ssa.cbm_id,
    ssa.am_id AS account_manager_id,
    d.division_id,
    rt.retail_type_id,
    pnv.product_name_id,
    mv.model_id,
    bn.brand_id,
    g.group_id_id,
    bid.tool_id_id AS base_id_id,
    1 AS item_type_id,
    ssa.item_stat_id
	,case 
	when wmcal.wc_id_ty is null then 0
	when wmcal.wc_id_ty <=4 then 1
	else 0
	end as is_l4_ty
	,case 
	when wc_id_ty is null then 0
	when wc_id_ty <=13 then 1
	else 0
	end as is_l13_ty
	,case
		when wc_id_ty is null then 0
		when wc_id_ty <=52 then 1
		else 0
	end as is_l52_ty
	,case 
	when wmcal.wc_id_ly is null then 0
	when wmcal.wc_id_ly <=4 then 1
	else 0
	end as is_l4_ly
	,case 
	when wc_id_ly is null then 0
	when wc_id_ly <=13 then 1
	else 0
	end as is_l13_ly
	,case
		when wc_id_ly is null then 0
		when wc_id_ly <=52 then 1
		else 0
	end as is_l52_ly
   FROM ssa
     LEFT JOIN tv ON tv.tool_id::text = ssa.item_id::text
     LEFT JOIN g ON g.tool_id::text = tv.tool_id::text
     LEFT JOIN wmcal ON wmcal.date = ssa.sale_date
     LEFT JOIN d ON d.division_name = ssa.division
     LEFT JOIN rt ON ssa.retail_type_id = rt.retail_type_id
     LEFT JOIN mv ON mv.model_name::text = ssa.model
     LEFT JOIN pnv ON pnv.product_name::text = ssa.product_name
     LEFT JOIN bn ON bn.brand_name = ssa.brand_name
     LEFT JOIN bid ON bid.tool_id::text = ssa.base_id
     )
     ;