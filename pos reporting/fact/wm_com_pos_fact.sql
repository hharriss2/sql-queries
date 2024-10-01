create or replace view power_bi.wm_com_pos_fact as 
(
 WITH rs AS 
(
SELECT 
    id
    ,model
    ,division
    ,tool_id
    ,product_name
    ,group_id_id
    ,cbm_id
    ,cat
    ,base_id
    ,sale_date
    ,wm_week
    ,brand_name
    ,base_upc
    ,units
    ,sales
    ,item_type
    ,retail_type_id
    ,is_put
    ,item_type_id
    ,account_manager_id
    ,is_top_100_item
    ,category_id
FROM pos_reporting.wm_com_pos
)
, tv AS (
SELECT 
    item_id as tool_id
    ,item_id_id::bigint as tool_id_id
FROM power_bi.dim_wm_item_id
)
, pnv AS (
    SELECT product_name,
        product_name_id::bigint as product_name_id
    FROM power_bi.dim_product_names
)
, mv AS (
    SELECT model_name,
        model_id::bigint as model_id
    FROM power_bi.dim_models
)
, wc_ty AS (
    SELECT DISTINCT t1.wm_date,
    dense_rank() OVER (ORDER BY t1.wm_date DESC) AS wc_id
    FROM power_bi.wm_calendar_view t1
    WHERE t1.date <= (now()::date - '7 days'::interval)
    ORDER BY t1.wm_date DESC
    LIMIT 52
)
, wc_ly AS (
    SELECT DISTINCT t1.wm_date,
    dense_rank() OVER (ORDER BY t1.wm_date DESC) AS wc_id
    FROM power_bi.wm_calendar_view t1
    WHERE t1.date <= (now()::date - '1 year'::interval - '7 days'::interval)
    ORDER BY t1.wm_date DESC
    LIMIT 52
)
, wmcal AS (
    SELECT wcv.wmcal_id,
    wcv.date,
    wcv.wm_week,
    wcv.wm_year,
    wcv.wm_date,
    wcv.month,
    wc_ty.wc_id AS wc_id_ty,
    wc_ly.wc_id AS wc_id_ly
    FROM power_bi.wm_calendar_view wcv
        LEFT JOIN wc_ty ON wcv.wm_date = wc_ty.wm_date
        LEFT JOIN wc_ly ON wcv.wm_date = wc_ly.wm_date
)
, bn AS (
    SELECT brand_id::bigint as brand_id,
    brand_name
    FROM power_bi.dim_brand_name
)
, d AS (
    SELECT divisions_view.division_id,
    divisions_view.division_name
    FROM power_bi.divisions_view
)
, bid AS (
SELECT 
    item_id as tool_id
    ,item_id_id as tool_id_id
FROM power_bi.dim_item_id_view_pos
)
,budcal as --walmart budget calendar
( -- assign the walmart calendar id for the budget calendar
select * 
from power_bi.wm_budget_calendar
)

 SELECT DISTINCT 
    rs.id
    ,rs.units AS pos_qty
    ,rs.sales AS pos_sales
    ,wmcal.wmcal_id
    ,tv.tool_id_id
    ,rs.cbm_id
    ,rs.account_manager_id
    ,d.division_id
    ,rs.retail_type_id
    ,pnv.product_name_id
    ,mv.model_id
    ,bn.brand_id
    ,rs.group_id_id
    ,bid.tool_id_id AS base_id_id
    ,rs.item_type_id
    ,budcal.wm_cal_id as wm_budget_cal_id
    ,rs.category_id
    ,is_top_100_item
    ,rs.is_put
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
FROM rs
LEFT JOIN wmcal ON wmcal.date = rs.sale_date
LEFT JOIN mv ON rs.model = mv.model_name::text
LEFT JOIN bn ON bn.brand_name = rs.brand_name
LEFT JOIN d ON d.division_name = rs.division
LEFT JOIN tv ON tv.tool_id::bigint = rs.tool_id::bigint
LEFT JOIN pnv ON pnv.product_name::text = rs.product_name
LEFT JOIN bid ON rs.tool_id::bigint = bid.tool_id::bigint
left join budcal on rs.wm_week = budcal.wm_date
)
;