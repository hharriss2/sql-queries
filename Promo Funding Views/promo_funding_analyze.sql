 WITH pfc AS (
         SELECT pfc_1.id,
            pfc_1.cat,
            pfc_1.model,
            pfc_1.product_name,
            pfc_1.tool_id,
            pfc_1.start_date,
            pfc_1.end_date,
            pfc_1.funding_amt,
            pfc_1.promo_type,
            pfc_1.suggested_retail,
            pfc_1.submit_date
           FROM power_bi.promo_funding_clean pfc_1
          WHERE pfc_1.cat = 'Seating'::text AND pfc_1.promo_type <> 'Holiday 2021'::text
        ), rs AS (
         SELECT retail_sales.id,
            retail_sales.tool_id,
            retail_sales.product_name,
            retail_sales.upc,
            retail_sales.brand_name,
            retail_sales.base_upc,
            retail_sales.sale_date,
            retail_sales.wm_week,
            retail_sales.units,
            retail_sales.sales
           FROM pos_reporting.retail_sales
          WHERE retail_sales.units >= 0 AND retail_sales.sales > 0::numeric
        ), l_52 AS (
         SELECT retail_sales.tool_id,
            sum(retail_sales.units::numeric(10,2)) / count(DISTINCT retail_sales.wm_week)::numeric AS l_52_average
           FROM pos_reporting.retail_sales
          WHERE (retail_sales.wm_week IN ( SELECT DISTINCT retail_sales2_1.wm_week
                   FROM pos_reporting.retail_sales retail_sales2_1
                  WHERE retail_sales2_1.wm_week <> (( SELECT max(retail_sales2_2.wm_week) AS max
                           FROM pos_reporting.retail_sales retail_sales2_2))
                  ORDER BY retail_sales2_1.wm_week DESC
                 LIMIT 52)) AND (retail_sales.tool_id::integer IN ( SELECT DISTINCT pfc_1.tool_id
                   FROM pos_reporting.promo_funding_clean pfc_1
                  WHERE pfc_1.cat = 'Seating'::text))
          GROUP BY retail_sales.tool_id
        ), bb AS (
         SELECT most_recent_scrape.item_id,
            most_recent_scrape.available
           FROM scrape_data.most_recent_scrape
        )
 SELECT DISTINCT pfc.tool_id,
        CASE
            WHEN bb.available = true THEN 'Available'::text
            ELSE 'Unavailable'::text
        END AS "Is Available?",
    pfc.cat AS "Category",
    pfc.product_name AS "Product Name",
    pfc.promo_type AS "Promo Type",
    sum(rs.units) AS "Unit Sales During Promo",
    pfc.funding_amt AS "Funding Amount",
    sum(rs.units)::numeric * pfc.funding_amt AS "Projected Co op Spending",
    avg(rs.units)::numeric(10,2) AS "Avg Units During Promo per Week Sold",
    l_52.l_52_average::numeric(10,2) AS "Avg units during last 52 per Week Sold"
   FROM pfc
     JOIN rs ON pfc.tool_id = rs.tool_id::integer
     JOIN l_52 ON rs.tool_id = l_52.tool_id
     JOIN bb ON l_52.tool_id = bb.item_id::text
  WHERE pfc.start_date <= rs.wm_week AND pfc.end_date >= rs.wm_week
  GROUP BY pfc.tool_id, bb.available, pfc.cat, pfc.product_name, pfc.funding_amt, l_52.l_52_average, pfc.promo_type;