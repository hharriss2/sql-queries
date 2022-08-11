/*START ECOM FACT VIEW*/
create or replace view power_bi.wm_com_pos_fact as (
WITH rs AS (
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
            is_put
           FROM pos_reporting.wm_com_pos
        ), c AS (
         SELECT category_view.category_id,
            category_view.category_name,
            category_view.am_id
           FROM power_bi.category_view
        ), cbm AS (
         SELECT cat_by_model.model,
            cat_by_model.cat,
            cat_by_model.sub_cat,
            cat_by_model.cbm_id
           FROM cat_by_model
        ), tv AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), pnv AS (
         SELECT product_name_view_pbix.product_name,
            product_name_view_pbix.product_name_id
           FROM power_bi.product_name_view_pbix
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
        ), bid AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), a AS (
         SELECT account_manager_view.account_manager_id,
            account_manager_view.account_manager
           FROM power_bi.account_manager_view
        ), itype AS (
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
/*END ECOMM FACT VIEW*/

/*START STORES FACT VIEW*/
create or replace view power_bi.wm_stores_pos_fact as (
with 
    ssa as 
            (
				select * 
				from pos_reporting.wm_stores_pos
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
,ssa.cbm_id
,ssa.am_id AS account_manager_id
,d.division_id
, rt.retail_type_id
, pnv.product_name_id
, mv.model_id
,bn.brand_id
,g.group_id_id
,bid.tool_id_id as base_id_id
,1 as item_type_id
,ssa.item_stat_id
from ssa
left join tv on tv.tool_id = ssa.item_id::text-- tool id dim
left join g on g.tool_id::text = tv.tool_id-- group id dim
left join wmcal on wmcal.date = ssa.sale_date-- gets calendar dim
--left join d on model_tool.division = d.division_name --division dim
left join d on d.division_name= ssa.division --get division dim other way
left join rt on ssa.retail_type_id = rt.retail_type_id -- gets retail type dim
left join mv on mv.model_name = ssa.model-- gets model dim
left join pnv on pnv.product_name = ssa.product_name -- gets product name dim
LEFT JOIN bn ON bn.brand_name = ssa.brand_name
LEFT JOIN bid ON bid.tool_id::text = ssa.base_id::text
)
;
/*END STORES FACT VIEW*/