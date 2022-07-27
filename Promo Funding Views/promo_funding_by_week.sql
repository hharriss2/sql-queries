create or replace view power_bi.promo_funding_tracker_by_week2 as (
 SELECT t1.id as pfid,
    m.model_id,
    d.division_id,
    cbm.cbm_id,
    t.tool_id_id,
    a.account_manager_id,
    t1.units,
    t1.funding_amt,
    pt.promo_id,
    wmw1.wmcal_id::bigint AS wm_start_date_id,
    wmw2.wmcal_id::bigint AS wm_end_date_id,
    pn.product_name_id,
    g.group_id_id,
    t1.suggested_retail,
    rp.retail_price_id,
    wmw3.wmcal_id AS submit_week_id,
    t1.sales,
    t1.sales_funding,
    w.wmcal_id,
    b.brand_id
   FROM ( SELECT pf.id,
            s.id AS sid,
            pf.model,
            pf.tool_id,
            s.units,
            pf.funding_amt,
            pf.promo_type,
            pf.start_date,
            pf.end_date,
           coalesce(tpb.product_name, pf.product_name) as product_name,
           coalesce(tpb.brand_name, s.brand_name) as brand_name,
            pf.suggested_retail,
            pf.submit_date AS submit_week,
            (s.units::numeric * pf.funding_amt)::numeric(10,2) AS sales_funding,
            s.sales::real AS sales,
            sale_date
           FROM pos_reporting.retail_sales s
          RIGHT JOIN pos_reporting.promo_funding_clean2 pf ON s.tool_id::integer = pf.tool_id
          left join lookups.tool_pn_brand tpb on tpb.tool_id = s.tool_id
          WHERE s.sale_date >= pf.start_date 
          AND s.sale_date <= pf.end_date 
          AND pf.funding_amt > 0::numeric
          ) t1
     JOIN cat_by_model cbm ON t1.model::text = cbm.model
     JOIN category c ON cbm.cat = c.category_name
     JOIN model_view m ON t1.model::text = m.model_name::text
     JOIN tool_id_view t ON t1.tool_id::text = t.tool_id::text
     JOIN account_manager a ON a.account_manager_id = c.am_id
     JOIN ( 
     	SELECT DISTINCT products_raw.model,
            products_raw.division
       FROM products_raw
       ) t2 ON t2.model = t1.model::text
     LEFT JOIN divisions d ON d.division_name = t2.division
     LEFT JOIN power_bi.promo_type pt ON pt.promo_name = t1.promo_type
     LEFT JOIN power_bi.wm_calendar_view wmw1 ON wmw1.date = t1.start_date
     LEFT JOIN power_bi.wm_calendar_view wmw2 ON wmw2.date = t1.end_date
     LEFT JOIN power_bi.wm_calendar_view wmw3 ON wmw3.date = t1.submit_week
     LEFT JOIN power_bi.wm_calendar_view w on w.date = t1.sale_date
     LEFT JOIN power_bi.product_name_view_pbix pn ON pn.product_name::text = t1.product_name
     LEFT JOIN power_bi.group_id_view g ON g.tool_id = t1.tool_id
     LEFT JOIN power_bi.retail_price rp ON rp.item_id = t1.tool_id
     left join power_bi.brand_name b on t1.brand_name = b.brand_name
     
     );