/*START NEW VIEW*/
 create or replace view  power_bi.promo_funding_calc_pbix_view2 as (
 WITH retail_funding AS (
         SELECT DISTINCT pf.id as pf_id,
            s.id AS sid,
            pf.model,
            s.wm_week,
            pf.tool_id,
            s.units,
            pf.funding_amt,
            pf.promo_type,
            pf.start_date,
            pf.end_date,
            pf.submit_date::date AS submit_week,
            pf.suggested_retail,
           coalesce(tpb.product_name, pf.product_name) as product_name,
           coalesce(tpb.brand_name, s.brand_name) as brand_name,
            (s.units::numeric * pf.funding_amt)::numeric(10,2) AS sales_funding,
            s.sales::real AS sales
           FROM pos_reporting.retail_sales s
             RIGHT JOIN pos_reporting.promo_funding_clean2 pf ON s.tool_id::integer = pf.tool_id
             left join lookups.tool_pn_brand tpb
             on s.tool_id = tpb.tool_id
          WHERE s.sale_date >= pf.start_date AND s.sale_date <= pf.end_date AND pf.funding_amt > 0::numeric
        ), cbm AS (
         SELECT cat_by_model.model,
            cat_by_model.cat,
            cat_by_model.sub_cat,
            cat_by_model.cbm_id,
            cat_by_model.sams_only
           FROM cat_by_model
        ), c AS (
         SELECT category_view.category_id,
            category_view.category_name,
            category_view.am_id
           FROM power_bi.category_view
        ), m AS (
         SELECT model_view_pbix.model_name,
            model_view_pbix.model_id
           FROM power_bi.model_view_pbix
        ), t AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), a AS (
         SELECT account_manager_view.account_manager_id,
            account_manager_view.account_manager
           FROM power_bi.account_manager_view
        ), pr AS (
         SELECT DISTINCT products_raw.model,
            products_raw.division,
            products_raw.product_name
           FROM products_raw
        ), d AS (
         SELECT divisions_view.division_id,
            divisions_view.division_name
           FROM power_bi.divisions_view
        ), pt AS (
         SELECT promo_type.promo_id,
            promo_type.promo_name,
            promo_type.short_name,
            promo_type.is_accrued
           FROM power_bi.promo_type
        ), wmw1 AS (
         select  wmcal_id as wm_cal_id_1
         	,date::date
         	,wm_week
         	,wm_year
         	,wm_date
         	,month
         from power_bi.wm_calendar_view
        ), wmw2 AS (
         select wmcal_id as wm_cal_id_2
         	,date::date
         	,wm_week
         	,wm_year
         	,wm_date
         	,month
         from power_bi.wm_calendar_view
        ), wmw3 AS (
         select wmcal_id as wm_cal_id_3
         	,date::date
         	,wm_week
         	,wm_year
         	,wm_date
         	,month 
         from power_bi.wm_calendar_view
        ), pn AS (
         SELECT product_name_view_pbix.product_name,
            product_name_view_pbix.product_name_id
           FROM power_bi.product_name_view_pbix
        ), g AS (
         SELECT group_id_view.tool_id,
            group_id_view.group_id,
            group_id_view.collection_name,
            group_id_view.group_id_id,
            group_id_view.concat_gid_name
           FROM power_bi.group_id_view
        ), rp AS (
         SELECT retail_price.retail_price_id,
            retail_price.item_id,
            retail_price.available,
            retail_price.price_retail,
            retail_price.price_was
           FROM power_bi.retail_price
        ), bn as (
        	select * 
        	from power_bi.brand_name
        	)
 SELECT retail_funding.pf_id,
    m.model_id,
    d.division_id,
    cbm.cbm_id,
    t.tool_id_id,
    a.account_manager_id,
    sum(retail_funding.units)::integer AS units,
    retail_funding.funding_amt,
    pt.promo_id,
    wmw1.wm_cal_id_1 AS start_week_id,
    wmw2.wm_cal_id_2 AS end_week_id,
    wmw3.wm_cal_id_3 AS submit_week_id,
    retail_funding.suggested_retail,
    pn.product_name_id,
    rp.retail_price_id,
    g.group_id_id,
    sum(retail_funding.sales::numeric(10,2)) AS sales,
    sum(retail_funding.sales_funding)::numeric(10,2) AS funding_amt_total,
    brand_id
   FROM retail_funding
     JOIN cbm ON retail_funding.model::text = cbm.model
     JOIN c ON cbm.cat = c.category_name
     JOIN m ON retail_funding.model::text = m.model_name::text
     JOIN t ON retail_funding.tool_id::text = t.tool_id::text
     JOIN a ON a.account_manager_id = c.am_id
     JOIN pr ON retail_funding.model::text = pr.model
     LEFT JOIN divisions d ON pr.division = d.division_name
     LEFT JOIN pt ON retail_funding.promo_type = pt.promo_name
     LEFT JOIN wmw1 ON retail_funding.start_date = wmw1.date
     LEFT JOIN wmw2 ON retail_funding.end_date = wmw2.date
     LEFT JOIN wmw3 ON retail_funding.submit_week = wmw3.date
     LEFT JOIN pn ON retail_funding.product_name = pn.product_name::text
     LEFT JOIN g ON retail_funding.tool_id = g.tool_id
     LEFT JOIN rp ON retail_funding.tool_id = rp.item_id
     left join bn on retail_funding.brand_name = bn.brand_name
  GROUP BY retail_funding.pf_id, m.model_id, d.division_id, cbm.cbm_id, t.tool_id_id, a.account_manager_id, g.group_id_id, retail_funding.funding_amt, pt.promo_id, wmw1.wm_cal_id_1, wmw2.wm_cal_id_2,wmw3.wm_cal_id_3, pn.product_name_id, retail_funding.suggested_retail, rp.retail_price_id, bn.brand_id
  );
  /*END VIEW*/