
create or replace view dapl_raw.dsv_orders_3p_insert_pos_view as 
(
with wcf1 as 
(
select
product_name
,item_id
,model
,row_number () over (partition by model order by retailer_type_id desc) as model_seq
from clean_data.master_com_list

)
,wcf as 
(
select *
from wcf1
where model_seq = 1
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