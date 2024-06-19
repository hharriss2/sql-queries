--wm com pos fact must mirror wm stores pos fact so append can work on power bi
create or replace view power_bi.wm_com_pos_fact as
(
 WITH rs AS 
(
 SELECT wm_com_pos.id,
    wm_com_pos.model,
    wm_com_pos.division,
    wm_com_pos.tool_id,
    wm_com_pos.product_name,
    wm_com_pos.group_id_id,
    wm_com_pos.cbm_id,
    wm_com_pos.cat,
    wm_com_pos.base_id,
    wm_com_pos.sale_date,
    wm_com_pos.wm_week,
    wm_com_pos.brand_name,
    wm_com_pos.base_upc,
    wm_com_pos.units,
    wm_com_pos.sales,
    wm_com_pos.item_type,
    2 AS retail_type_id,
    wm_com_pos.is_put
   FROM pos_reporting.wm_com_pos
), c AS 
(
 SELECT category_view.category_id,
    category_view.category_name,
    category_view.am_id
   FROM power_bi.category_view
), cbm AS 
(
 SELECT cat_by_model.model,
    cat_by_model.cat,
    cat_by_model.sub_cat,
    cat_by_model.cbm_id
   FROM cat_by_model
)
, tv AS 
(
 SELECT tool_id_view.tool_id,
    tool_id_view.tool_id_id
   FROM power_bi.tool_id_view
)
, pnv AS 
(
 SELECT product_name_view_pbix.product_name,
    product_name_view_pbix.product_name_id
   FROM power_bi.product_name_view_pbix
)
, rt AS 
(
 SELECT retail_type.retail_type_id,
    retail_type.retail_type
   FROM power_bi.retail_type
)
, wmc AS
 (
 SELECT wm_catalog2.item_num,
    wm_catalog2.item_id,
    "left"(wm_catalog2.gtin, 13) AS gtin,
    wm_catalog2.item_description
   FROM wm_catalog2
)
, mv AS 
(
 SELECT model_view_pbix.model_name,
    model_view_pbix.model_id
   FROM power_bi.model_view_pbix
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
, bn AS 
(
 SELECT brand_name.brand_id,
    brand_name.brand_name
   FROM power_bi.brand_name
)
, d AS 
(
 SELECT divisions_view.division_id,
    divisions_view.division_name
   FROM power_bi.divisions_view
)
, bid AS 
(
 SELECT tool_id_view.tool_id,
    tool_id_view.tool_id_id
   FROM power_bi.tool_id_view
)
, a AS 
(
 SELECT account_manager_view.account_manager_id,
    account_manager_view.account_manager
   FROM power_bi.account_manager_view
)
, itype AS 
(
 SELECT lookup_item_type.item_type_id,
    lookup_item_type.item_type
   FROM lookup_item_type
)
 SELECT DISTINCT rs.id,
    rs.units AS pos_qty,
    rs.sales AS pos_sales,
    wmcal.wmcal_id,
    tv.tool_id_id,
    cbm.cbm_id,
    a.account_manager_id,
    d.division_id,
    rt.retail_type_id,
    pnv.product_name_id,
    mv.model_id,
    bn.brand_id,
    rs.group_id_id,
    bid.tool_id_id AS base_id_id,
    itype.item_type_id,
    rs.is_put
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
   FROM rs
     LEFT JOIN cbm ON rs.model = cbm.model
     LEFT JOIN c ON c.category_name = cbm.cat
     LEFT JOIN a ON a.account_manager_id = c.am_id
     LEFT JOIN wmc ON rs.base_upc = wmc.gtin
     LEFT JOIN wmcal ON wmcal.date = rs.sale_date
     LEFT JOIN mv ON rs.model = mv.model_name::text
     LEFT JOIN bn ON bn.brand_name = rs.brand_name
     LEFT JOIN d ON d.division_name = rs.division
     LEFT JOIN tv ON tv.tool_id::text = rs.tool_id
     LEFT JOIN pnv ON pnv.product_name::text = rs.product_name
     LEFT JOIN bid ON rs.tool_id = bid.tool_id::text
     LEFT JOIN rt ON rt.retail_type_id = rs.retail_type_id
     LEFT JOIN itype ON rs.item_type = itype.item_type
)     
     ;