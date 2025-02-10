--adds and updates dsv orders into the retail_link_pos table (main ecommerce table)
/*
old wm catalog. let's try to use the components version. 
 WITH wc AS 
 ( -- walmart catalog
SELECT 
    wm_catalog_3p.item_id
    ,wm_catalog_3p.model
    ,wm_catalog_3p.product_name
    ,wm_catalog_3p.upc
    ,wm_catalog_3p.inserted_at
FROM clean_data.wm_catalog_3p
)
, wcmax AS 
(
SELECT 
    wc.model
    ,max(wc.inserted_at) AS date_compare
FROM wc
GROUP BY wc.model
), wcf AS 
(
SELECT 
    wc.item_id
    ,wc.model
    ,wc.upc
    ,wc.product_name
FROM wc
JOIN wcmax 
ON wc.inserted_at = wcmax.date_compare AND wc.model = wcmax.model
)
 */
create or replace view dapl_raw.dsv_orders_3p_insert_pos_view as 
(
with wcf as 
(
select * 
from components.wm_catalog_3p
)
, wcal AS 
(
SELECT 
    wm_calendar_view.wmcal_id
    ,wm_calendar_view.date
    ,wm_calendar_view.wm_week
    ,wm_calendar_view.wm_year
    ,wm_calendar_view.wm_date
    ,wm_calendar_view.month
FROM power_bi.wm_calendar_view
)
 SELECT
    dsv.dsv_order_id
    ,COALESCE(wcf.item_id, 404::bigint) AS item_id
    ,wcf.upc
    ,dsv.sku AS model
    ,wcf.product_name
    ,dsv.order_date::date AS sale_date
    ,wcal.wm_date::integer - 100 AS wm_week
    ,dsv.qty AS units
    ,dsv.order_total AS sales
    ,'3P'::text AS item_type
    ,dsv.po_id
FROM pos_reporting.dsv_orders_3p dsv
LEFT JOIN wcf 
ON dsv.sku = wcf.model
LEFT JOIN wcal
ON wcal.date = dsv.order_date::date
WHERE 1 = 1 AND dsv.status <> 'Cancelled'::text
);