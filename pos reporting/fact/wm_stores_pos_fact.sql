create or replace view power_bi.wm_stores_pos_fact as 
(
WITH ssa AS 
 (
SELECT 
    id
    ,pos_qty
    ,pos_sales
    ,curr_repl_instock
    ,sale_date
    ,item_id
    ,cbm_id
    ,am_id
    ,division
    ,retail_type_id
    ,product_name
    ,model
    ,base_id
    ,brand_name
    ,item_stat_id
    ,group_id_id
    ,is_top_100_item
    ,category_id
FROM pos_reporting.wm_stores_pos
)
,wc_ty AS 
(
SELECT DISTINCT wm_date
,dense_rank() OVER (ORDER BY wm_date DESC) AS wc_id
FROM power_bi.wm_calendar_view
WHERE date <= (now()::date - '7 days'::interval)
ORDER BY wm_date DESC
LIMIT 52
)
,wc_ly AS 
(
SELECT DISTINCT 
wm_date
,dense_rank() OVER (ORDER BY wm_date DESC) AS wc_id
FROM power_bi.wm_calendar_view 
WHERE date <= (now()::date - '1 year'::interval - '7 days'::interval)
ORDER BY wm_date DESC
LIMIT 52
)
,wmcal AS 
(
SELECT 
    wcv.wmcal_id
    ,wcv.date
    ,wcv.wm_week
    ,wcv.wm_year
    ,wcv.wm_date
    ,wcv.month
    ,wc_ty.wc_id AS wc_id_ty
    ,wc_ly.wc_id AS wc_id_ly
FROM power_bi.wm_calendar_view wcv
LEFT JOIN wc_ty 
ON wcv.wm_date = wc_ty.wm_date
LEFT JOIN wc_ly 
ON wcv.wm_date = wc_ly.wm_date
)
, d AS 
(
SELECT
    division_id
    ,division_name
FROM power_bi.divisions_view
)
, tv AS (
SELECT 
    item_id as tool_id
    ,item_id_id::bigint as tool_id_id
FROM power_bi.dim_wm_item_id
)
, pnv AS (
SELECT 
	product_name,
    product_name_id::bigint as product_name_id
FROM power_bi.dim_product_names
)
,bid AS 
(
SELECT 
    item_id as tool_id
    ,item_id_id as tool_id_id
FROM power_bi.dim_wm_item_id
)
, bn AS 
(
SELECT  brand_id::bigint as brand_id,
    brand_name
FROM power_bi.dim_brand_name
)
,rt AS 
(
SELECT retail_type.retail_type_id,
retail_type.retail_type
FROM power_bi.retail_type
)
, mv AS (
    SELECT model_name,
        model_id::bigint as model_id
    FROM power_bi.dim_models
)
,budcal as --walmart budget calendar
( -- assign the walmart calendar id for the budget calendar
select * 
from power_bi.wm_budget_calendar
)
SELECT ssa.id
    ,ssa.pos_qty
    ,ssa.pos_sales
    ,wmcal.wmcal_id
    ,tv.tool_id_id
    ,ssa.cbm_id
    ,ssa.am_id AS account_manager_id
    ,d.division_id
    ,ssa.retail_type_id
    ,pnv.product_name_id
    ,mv.model_id
    ,bn.brand_id
    ,ssa.group_id_id
    ,bid.tool_id_id::bigint AS base_id_id
    ,1 AS item_type_id
    ,budcal.wm_cal_id as wm_budget_cal_id
    ,ssa.category_id
    ,is_top_100_item
    ,ssa.item_stat_id
    ,CASE
        WHEN wmcal.wc_id_ty IS NULL THEN 0
        WHEN wmcal.wc_id_ty <= 4 THEN 1
        ELSE 0
    END AS is_l4_ty
    ,CASE
        WHEN wmcal.wc_id_ty IS NULL THEN 0
        WHEN wmcal.wc_id_ty <= 13 THEN 1
        ELSE 0
    END AS is_l13_ty
    ,CASE
        WHEN wmcal.wc_id_ty IS NULL THEN 0
        WHEN wmcal.wc_id_ty <= 52 THEN 1
        ELSE 0
    END AS is_l52_ty
    ,CASE
        WHEN wmcal.wc_id_ly IS NULL THEN 0
        WHEN wmcal.wc_id_ly <= 4 THEN 1
        ELSE 0
    END AS is_l4_ly
    ,CASE
        WHEN wmcal.wc_id_ly IS NULL THEN 0
        WHEN wmcal.wc_id_ly <= 13 THEN 1
        ELSE 0
    END AS is_l13_ly
    ,CASE
        WHEN wmcal.wc_id_ly IS NULL THEN 0
        WHEN wmcal.wc_id_ly <= 52 THEN 1
        ELSE 0
    END AS is_l52_ly
   FROM ssa
     LEFT JOIN tv ON tv.tool_id::text = ssa.item_id::text
     LEFT JOIN wmcal ON wmcal.date = ssa.sale_date
     LEFT JOIN d ON d.division_name = ssa.division
     LEFT JOIN mv ON mv.model_name::text = ssa.model
     LEFT JOIN pnv ON pnv.product_name::text = ssa.product_name
     LEFT JOIN bn ON bn.brand_name = ssa.brand_name
     LEFT JOIN bid ON bid.tool_id::bigint = ssa.base_id
     left join budcal on wmcal.wm_date::integer = budcal.wm_date
)
;
