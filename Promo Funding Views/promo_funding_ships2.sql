 create or replace view power_bi.promo_funding_ships2 as (
 SELECT t1.pfid,
    m.model_id,
    d.division_id,
    cbm.cbm_id,
    t.tool_id_id,
    a.account_manager_id,
    sum(t1.units)::integer AS units,
    t1.funding_amt,
    pt.promo_id,
    t1.suggested_retail,
    g.group_id_id,
    wmw1.wmcal_id AS start_week_id,
    wmw2.wmcal_id AS end_week_id,
    pn.product_name_id,
    rp.retail_price_id,
    sum(t1.sales) AS ship_sales,
    sum(t1.sales_funding)::numeric(10,2) AS funding_amt_total,
    b.brand_id
   FROM ( SELECT pf.id AS pfid,
            s.id AS sid,
            pf.model,
            pf.tool_id,
            s.units,
            pf.funding_amt,
            pf.suggested_retail,
            pf.start_date,
            pf.end_date,
            pf.promo_type,
            tpn.brand_name,
            (s.units::numeric * pf.funding_amt)::numeric(10,2) AS sales_funding,
            s.sales
           FROM ships_schema.ships s
           RIGHT JOIN pos_reporting.promo_funding_clean2 pf ON s.model::text = pf.model::text
           left join lookups.tool_pn_brand tpn on pf.tool_id::text = tpn.tool_id
           WHERE s.date_shipped >= pf.start_date 
           AND s.date_shipped <= pf.end_date 
           AND pf.funding_amt > 0::numeric 
           AND s.sales > 0::double precision 
           AND s.retailer::text = 'Walmart.com'::text
         
          GROUP BY pf.id
          	,s.id
          	, pf.model
          	, pf.tool_id
          	, pf.start_date
          	, pf.end_date
          	, pf.funding_amt
          	, pf.promo_type
          	, pf.suggested_retail
          	, (s.units::numeric * pf.funding_amt)
          	, s.sales
          	,tpn.brand_name
          ) t1
     JOIN cat_by_model cbm ON t1.model::text = cbm.model
     JOIN category c ON cbm.cat = c.category_name
     JOIN model_view m ON t1.model::text = m.model_name::text
     JOIN power_bi.tool_id_view t ON t1.tool_id::text = t.tool_id::text
     JOIN account_manager a ON a.account_manager_id = c.am_id
     JOIN ( SELECT DISTINCT products_raw.model,
            products_raw.division,
            products_raw.product_name
           FROM products_raw
           ) t2 ON t2.model = t1.model::text
     LEFT JOIN divisions d ON d.division_name = t2.division
     LEFT JOIN power_bi.promo_type pt ON pt.promo_name = t1.promo_type
     LEFT JOIN power_bi.product_name_view_pbix pn ON pn.product_name::text = t2.product_name
     LEFT JOIN power_bi.group_id_view g ON g.tool_id = t1.tool_id
     LEFT JOIN power_bi.retail_price rp ON rp.item_id = t1.tool_id
     left join power_bi.brand_name b on t1.brand_name =  b.brand_name
     JOIN power_bi.wm_calendar_view wmw1 ON wmw1.date = t1.start_date
     JOIN power_bi.wm_calendar_view wmw2 ON wmw2.date = t1.end_date
  GROUP BY t1.pfid, m.model_id, d.division_id, cbm.cbm_id, t.tool_id_id, a.account_manager_id, pn.product_name_id, t1.funding_amt, t1.suggested_retail, g.group_id_id, pt.promo_id, wmw1.wmcal_id, wmw2.wmcal_id, rp.retail_price_id, b.brand_id

  )
  ;