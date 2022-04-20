 SELECT t1.id,
    t1.pos_qty,
    t1.pos_sales,
    t1.curr_repl_instock,
    t1.daily AS sale_date,
    w.item_num AS item_id,
    t1.cat,
    t1.sub_cat,
    t1.division,
    t1.retail_type_id,
    t1.product_name,
    t1.model,
    t1.base_id,
    t1.brand_name
   FROM ( WITH ssa AS (
                 SELECT DISTINCT ssa_1.id,
                    COALESCE(recent_item_num.prime_item_num, ssa_1.prime_item_nbr::integer) AS prime_item_nbr,
                    ssa_1.prime_item_desc,
                    ssa_1.item_nbr,
                    ssa_1.item_flags,
                    ssa_1.item_desc_1,
                    ssa_1.upc,
                    ssa_1.vendor_stk_nbr,
                    ssa_1.vendor_name,
                    ssa_1.vendor_nbr,
                    ssa_1.vendor_sequence_nbr,
                    ssa_1.wm_week,
                    ssa_1.daily,
                    ssa_1.unit_retail,
                    ssa_1.avg_retail,
                    ssa_1.pos_qty,
                    ssa_1.pos_sales,
                    ssa_1.curr_repl_instock,
                    1 AS retail_type_id
                   FROM sales_stores_auto ssa_1
                     LEFT JOIN ( SELECT DISTINCT
                                CASE
                                    WHEN dupe_lookup.item_description IS NOT NULL THEN dupe_lookup.item_num
                                    ELSE all_item_nbrs.prime_item_nbr::integer
                                END AS prime_item_num,
                            recent_item_desc.prime_item_desc,
                                CASE
                                    WHEN dupe_lookup.item_description IS NOT NULL THEN dupe_lookup.item_id
                                    WHEN dupe_lookup.item_description IS NULL THEN model_tool.tool_id::text
                                    ELSE w_1.item_id
                                END AS tool_id
                           FROM ( SELECT DISTINCT sales_stores_auto.prime_item_desc,
                                    max(sales_stores_auto.daily) AS date_compare
                                   FROM sales_stores_auto
                                  WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text
                                  GROUP BY sales_stores_auto.prime_item_desc) recent_item_desc
                             JOIN ( SELECT DISTINCT sales_stores_auto.prime_item_nbr,
                                    sales_stores_auto.prime_item_desc,
                                    sales_stores_auto.daily
                                   FROM sales_stores_auto
                                  WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text) all_item_nbrs ON recent_item_desc.prime_item_desc = all_item_nbrs.prime_item_desc
                             LEFT JOIN wm_catalog2 w_1 ON w_1.item_num = all_item_nbrs.prime_item_nbr::integer
                             LEFT JOIN ( SELECT DISTINCT s.model,
                                    s.tool_id
                                   FROM ( SELECT ships.model,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  GROUP BY ships.model) ship_model
                                     JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text) model_tool ON model_tool.tool_id::text = w_1.item_id
                             LEFT JOIN ( SELECT dupe_store_records.item_num,
                                    dupe_store_records.item_description,
                                    dupe_store_records.item_id
                                   FROM ( SELECT DISTINCT w_2.item_num,
    w_2.item_description,
    w_2.item_id
   FROM wm_catalog2 w_2
  WHERE (w_2.item_description IN ( SELECT t1_1.prime_item_desc
     FROM ( SELECT DISTINCT all_item_nbrs_1.prime_item_nbr,
        recent_item_desc_1.prime_item_desc
       FROM ( SELECT DISTINCT sales_stores_auto.prime_item_desc,
          max(sales_stores_auto.daily) AS date_compare
         FROM sales_stores_auto
        WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text
        GROUP BY sales_stores_auto.prime_item_desc) recent_item_desc_1
         JOIN ( SELECT DISTINCT sales_stores_auto.prime_item_nbr,
          sales_stores_auto.prime_item_desc,
          sales_stores_auto.daily
         FROM sales_stores_auto
        WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text) all_item_nbrs_1 ON recent_item_desc_1.prime_item_desc = all_item_nbrs_1.prime_item_desc
      WHERE recent_item_desc_1.date_compare = all_item_nbrs_1.daily) t1_1
    GROUP BY t1_1.prime_item_desc
   HAVING count(t1_1.prime_item_desc) > 1))) dupe_store_records
                                  WHERE (dupe_store_records.item_id IN ( SELECT DISTINCT s.tool_id
   FROM ( SELECT ships.model,
      max(ships.date_shipped) AS date_compare
     FROM ships_schema.ships
    GROUP BY ships.model) ship_model
     JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text)) AND (dupe_store_records.item_num <> ALL (ARRAY[551606155, 551606156, 569020027]))) dupe_lookup ON dupe_lookup.item_description = w_1.item_description
                          WHERE recent_item_desc.date_compare = all_item_nbrs.daily AND (all_item_nbrs.prime_item_nbr <> ALL (ARRAY['551606155'::text, '551606156'::text, '569020027'::text])) AND NOT (all_item_nbrs.prime_item_desc IN ( SELECT DISTINCT t2.item_description
                                   FROM ( SELECT dupe_store_records.item_num,
    dupe_store_records.item_description,
    dupe_store_records.item_id
   FROM ( SELECT DISTINCT w_2.item_num,
      w_2.item_description,
      w_2.item_id
     FROM wm_catalog2 w_2
    WHERE (w_2.item_description IN ( SELECT t1_1.prime_item_desc
       FROM ( SELECT DISTINCT all_item_nbrs_1.prime_item_nbr,
          recent_item_desc_1.prime_item_desc
         FROM ( SELECT DISTINCT sales_stores_auto.prime_item_desc,
            max(sales_stores_auto.daily) AS date_compare
           FROM sales_stores_auto
          WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text
          GROUP BY sales_stores_auto.prime_item_desc) recent_item_desc_1
           JOIN ( SELECT DISTINCT sales_stores_auto.prime_item_nbr,
            sales_stores_auto.prime_item_desc,
            sales_stores_auto.daily
           FROM sales_stores_auto
          WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text) all_item_nbrs_1 ON recent_item_desc_1.prime_item_desc = all_item_nbrs_1.prime_item_desc
        WHERE recent_item_desc_1.date_compare = all_item_nbrs_1.daily) t1_1
      GROUP BY t1_1.prime_item_desc
     HAVING count(t1_1.prime_item_desc) > 1))) dupe_store_records
  WHERE (dupe_store_records.item_id IN ( SELECT DISTINCT s.tool_id
     FROM ( SELECT ships.model,
        max(ships.date_shipped) AS date_compare
       FROM ships_schema.ships
      GROUP BY ships.model) ship_model
       JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
    WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text)) AND (dupe_store_records.item_num <> ALL (ARRAY[551606155, 551606156, 569020027]))) t2
                                  GROUP BY t2.item_description
                                 HAVING count(t2.item_description) > 1))) recent_item_num ON recent_item_num.prime_item_desc = ssa_1.prime_item_desc
                  WHERE ssa_1.fineline_description <> 'DOTCOM ONLY'::text
                  GROUP BY ssa_1.id, (COALESCE(recent_item_num.prime_item_num, ssa_1.prime_item_nbr::integer)), ssa_1.prime_item_desc, ssa_1.item_nbr, ssa_1.item_flags, ssa_1.item_desc_1, ssa_1.upc, ssa_1.vendor_stk_nbr, ssa_1.vendor_name, ssa_1.vendor_nbr, ssa_1.vendor_sequence_nbr, ssa_1.wm_week, ssa_1.daily, ssa_1.unit_retail, ssa_1.avg_retail, ssa_1.pos_qty, ssa_1.pos_sales
                ), wmc AS (
                 SELECT wm_catalog2.item_num,
                    wm_catalog2.item_id,
                    wm_catalog2.upc,
                    "left"(wm_catalog2.gtin, 13) AS gtin
                   FROM wm_catalog2
                ), wmcbid AS (
                 SELECT DISTINCT wm_catalog2.item_id,
                    wm_catalog2.upc,
                    "left"(wm_catalog2.gtin, 13) AS gtin
                   FROM wm_catalog2
                ), model_tool AS (
                 SELECT DISTINCT s.model,
                    s.tool_id,
                    s.division,
                    ship_model.date_compare
                   FROM ( SELECT ships.model,
                            max(ships.date_shipped) AS date_compare
                           FROM ships_schema.ships
                          GROUP BY ships.model) ship_model
                     JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text
                ), d AS (
                 SELECT divisions_view.division_id,
                    divisions_view.division_name
                   FROM power_bi.divisions_view
                ), cbm AS (
                 SELECT cat_by_model.model,
                    cat_by_model.cat,
                    cat_by_model.sub_cat,
                    cat_by_model.cbm_id,
                    cat_by_model.sams_only
                   FROM cat_by_model
                ), tv AS (
                 SELECT tool_id_view.tool_id,
                    tool_id_view.tool_id_id
                   FROM power_bi.tool_id_view
                ), pr AS (
                 WITH p AS (
                         SELECT products_raw.upc,
                            products_raw.product_name,
                            products_raw.model,
                            products_raw.wl_model,
                            products_raw.base_upc,
                            products_raw.division,
                            products_raw.retailer_id
                           FROM products_raw
                          WHERE 1 = 1 AND ((products_raw.model IN ( SELECT DISTINCT s.model
                                   FROM ( SELECT ships.upc,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  GROUP BY ships.upc) ship_model
                                     JOIN ships_schema.ships s ON s.upc::text = ship_model.upc::text
                                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])))) OR (products_raw.model IN ( SELECT DISTINCT w_2.supplier_stock_id
                                   FROM wm_catalog2 w_2
                                  WHERE w_2.supplier_stock_id <> ALL (ARRAY['WM3921E'::text, 'WM2906WJYF-DC'::text])))) AND products_raw.model !~~ '%OLD%'::text AND products_raw.product_name !~~ '%Displ%'::text
                        ), w AS (
                         SELECT DISTINCT
                                CASE
                                    WHEN dupe_lookup.item_description IS NOT NULL THEN dupe_lookup.item_num
                                    ELSE all_item_nbrs.prime_item_nbr::integer
                                END AS item_num,
                            recent_item_desc.prime_item_desc,
                                CASE
                                    WHEN dupe_lookup.item_description IS NOT NULL THEN dupe_lookup.item_id
                                    WHEN dupe_lookup.item_description IS NULL THEN model_tool_1.tool_id::text
                                    ELSE w_2.item_id
                                END AS item_id,
                            COALESCE(dupe_lookup.upc, w_2.upc) AS upc,
                            w_2.supplier_stock_id
                           FROM ( SELECT DISTINCT sales_stores_auto.prime_item_desc,
                                    max(sales_stores_auto.daily) AS date_compare
                                   FROM sales_stores_auto
                                  WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text
                                  GROUP BY sales_stores_auto.prime_item_desc) recent_item_desc
                             JOIN ( SELECT DISTINCT sales_stores_auto.prime_item_nbr,
                                    sales_stores_auto.prime_item_desc,
                                    sales_stores_auto.daily
                                   FROM sales_stores_auto
                                  WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text) all_item_nbrs ON recent_item_desc.prime_item_desc = all_item_nbrs.prime_item_desc
                             LEFT JOIN wm_catalog2 w_2 ON w_2.item_num = all_item_nbrs.prime_item_nbr::integer
                             LEFT JOIN ( SELECT DISTINCT s.model,
                                    s.tool_id
                                   FROM ( SELECT ships.model,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  GROUP BY ships.model) ship_model
                                     JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text) model_tool_1 ON model_tool_1.tool_id::text = w_2.item_id
                             LEFT JOIN ( SELECT dupe_store_records.item_num,
                                    dupe_store_records.item_description,
                                    dupe_store_records.item_id,
                                    dupe_store_records.upc
                                   FROM ( SELECT DISTINCT w_3.item_num,
    w_3.item_description,
    w_3.item_id,
    w_3.upc
   FROM wm_catalog2 w_3
  WHERE (w_3.item_description IN ( SELECT t1_1.prime_item_desc
     FROM ( SELECT DISTINCT all_item_nbrs_1.prime_item_nbr,
        recent_item_desc_1.prime_item_desc
       FROM ( SELECT DISTINCT sales_stores_auto.prime_item_desc,
          max(sales_stores_auto.daily) AS date_compare
         FROM sales_stores_auto
        WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text
        GROUP BY sales_stores_auto.prime_item_desc) recent_item_desc_1
         JOIN ( SELECT DISTINCT sales_stores_auto.prime_item_nbr,
          sales_stores_auto.prime_item_desc,
          sales_stores_auto.daily
         FROM sales_stores_auto
        WHERE sales_stores_auto.fineline_description <> 'DOTCOM ONLY'::text) all_item_nbrs_1 ON recent_item_desc_1.prime_item_desc = all_item_nbrs_1.prime_item_desc
      WHERE recent_item_desc_1.date_compare = all_item_nbrs_1.daily) t1_1
    GROUP BY t1_1.prime_item_desc
   HAVING count(t1_1.prime_item_desc) > 1))) dupe_store_records
                                  WHERE (dupe_store_records.item_id IN ( SELECT DISTINCT s.tool_id
   FROM ( SELECT ships.model,
      max(ships.date_shipped) AS date_compare
     FROM ships_schema.ships
    GROUP BY ships.model) ship_model
     JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text)) AND dupe_store_records.item_num <> 569020027) dupe_lookup ON dupe_lookup.item_description = w_2.item_description
                             LEFT JOIN ( SELECT DISTINCT s.tool_id,
                                    ship_upc.upc
                                   FROM ( SELECT ships.upc,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  GROUP BY ships.upc) ship_upc
                                     JOIN ships_schema.ships s ON s.upc::text = ship_upc.upc::text
                                  WHERE 1 = 1 AND s.date_shipped = ship_upc.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text) tool_upc ON COALESCE(tool_upc.tool_id::text = dupe_lookup.item_id, tool_upc.tool_id::text = model_tool_1.tool_id::text, tool_upc.tool_id::text = w_2.item_id)
                          WHERE recent_item_desc.date_compare = all_item_nbrs.daily AND all_item_nbrs.prime_item_nbr <> '569020027'::text
                        ), model_tool AS (
                         SELECT DISTINCT s.model,
                                CASE
                                    WHEN s.tool_id::text = ''::text THEN old_tool.tool_id
                                    ELSE s.tool_id
                                END AS tool_id,
                            s.division,
                            s.upc,
                            ship_model.date_compare
                           FROM ( SELECT ships.model,
                                    max(ships.date_shipped) AS date_compare
                                   FROM ships_schema.ships
                                  GROUP BY ships.model) ship_model
                             JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                             JOIN ( SELECT DISTINCT s_1.model,
                                    s_1.tool_id
                                   FROM ships_schema.ships s_1
                                     JOIN ( SELECT DISTINCT ships.model,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND ships.tool_id::text <> ''::text AND ships.tool_id::text <> '0'::text
  GROUP BY ships.model) model_tool_older ON s_1.model::text = model_tool_older.model::text
                                  WHERE 1 = 1 AND s_1.date_shipped = model_tool_older.date_compare AND s_1.tool_id::text <> '0'::text AND s_1.tool_id::text <> ''::text) old_tool ON s.model::text = old_tool.model::text
                          WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[])) AND s.tool_id::text <> '0'::text
                        ), model_upc AS (
                         SELECT s.model,
                            s.upc,
                            max(s.date_shipped) AS date_compare
                           FROM ships_schema.ships s
                             JOIN ( SELECT ships.upc,
                                    max(ships.date_shipped) AS date_compare2
                                   FROM ships_schema.ships
                                  WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[]))
                                  GROUP BY ships.upc) max_model ON s.upc::text = max_model.upc::text
                          WHERE 1 = 1 AND s.upc::text ~~ '0%'::text AND max_model.date_compare2 = s.date_shipped AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying, 'Walmart Stores'::character varying]::text[]))
                          GROUP BY s.model, s.upc
                        )
                 SELECT DISTINCT w_1.item_num,
                        CASE
                            WHEN model_tool.tool_id::text = ''::text THEN w_1.item_id
                            WHEN model_tool.tool_id IS NOT NULL THEN model_tool.tool_id::text
                            ELSE w_1.item_id
                        END AS item_id,
                    COALESCE(model_upc.model, p.model::character varying) AS model,
                    p.product_name,
                    p.division,
                    p.model AS p_model,
                    model_tool.model AS model_tool_model,
                    model_tool.tool_id,
                    model_upc.model AS upc_model,
                        CASE
                            WHEN w_1.upc IS NOT NULL THEN w_1.upc
                            WHEN w_1.upc IS NULL THEN p.upc
                            WHEN p.upc IS NULL THEN p.base_upc
                            ELSE NULL::text
                        END AS upc
                   FROM p
                     LEFT JOIN w w_1 ON COALESCE(p.base_upc = w_1.upc, p.upc = w_1.upc, p.model = w_1.supplier_stock_id)
                     LEFT JOIN model_tool ON model_tool.model::text = p.model
                     LEFT JOIN model_upc ON COALESCE(p.base_upc = model_upc.upc::text, p.upc = model_upc.upc::text)
                  WHERE 1 = 1 AND (p.retailer_id = ANY (ARRAY[1, 4]))
                ), pnv AS (
                 SELECT product_name_view_pbix.product_name,
                    product_name_view_pbix.product_name_id
                   FROM power_bi.product_name_view_pbix
                ), rs AS (
                 SELECT DISTINCT rs1.tool_id,
                    tool_brand.brand_name,
                    rs1.upc,
                    r3.base_upc
                   FROM pos_reporting.retail_sales rs1
                     LEFT JOIN ( SELECT r2.tool_id,
                            r1.brand_name
                           FROM ( SELECT DISTINCT retail_sales.tool_id,
                                    retail_sales.brand_name,
                                    max(retail_sales.sale_date) AS date_compare
                                   FROM pos_reporting.retail_sales
                                  WHERE retail_sales.brand_name IS NOT NULL
                                  GROUP BY retail_sales.tool_id, retail_sales.brand_name) r1
                             RIGHT JOIN ( SELECT r2_1.tool_id,
                                    max(r2_1.sale_date) AS date_compare
                                   FROM pos_reporting.retail_sales r2_1
                                  WHERE r2_1.brand_name IS NOT NULL
                                  GROUP BY r2_1.tool_id) r2 ON r1.tool_id = r2.tool_id
                          WHERE r1.date_compare = r2.date_compare) tool_brand ON tool_brand.tool_id = rs1.tool_id
                     LEFT JOIN ( SELECT DISTINCT tool_base.tool_id,
                            tool_base.base_upc
                           FROM ( SELECT t1_1.tool_id,
                                    t2.base_upc
                                   FROM ( SELECT retail_sales.tool_id,
    max(retail_sales.sale_date) AS date_compare
   FROM pos_reporting.retail_sales
  GROUP BY retail_sales.tool_id) t1_1
                                     JOIN pos_reporting.retail_sales t2 ON t1_1.tool_id = t2.tool_id
                                  WHERE t1_1.date_compare = t2.sale_date) tool_base) r3 ON r3.tool_id = rs1.tool_id
                ), c AS (
                 SELECT category_view.category_id,
                    category_view.category_name,
                    category_view.am_id
                   FROM power_bi.category_view
                ), scv AS (
                 SELECT sub_category_view.sub_cat_id,
                    sub_category_view.sub_cat_name
                   FROM power_bi.sub_category_view
                ), bid AS (
                 SELECT tool_id_view.tool_id,
                    tool_id_view.tool_id_id
                   FROM power_bi.tool_id_view
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
                ), rt AS (
                 SELECT retail_type.retail_type_id,
                    retail_type.retail_type
                   FROM power_bi.retail_type
                ), g AS (
                 SELECT group_id_view.tool_id,
                    group_id_view.group_id,
                    group_id_view.collection_name,
                    group_id_view.group_id_id,
                    group_id_view.concat_gid_name
                   FROM power_bi.group_id_view
                ), mv AS (
                 SELECT model_view_pbix.model_name,
                    model_view_pbix.model_id
                   FROM power_bi.model_view_pbix
                ), rsbid AS (
                 SELECT DISTINCT retail_sales.upc,
                    retail_sales.base_upc,
                    retail_sales.tool_id
                   FROM pos_reporting.retail_sales
                  WHERE retail_sales.upc = retail_sales.base_upc
                ), sl AS (
                 SELECT t1_1.prime_item_num,
                    t1_1.item_id,
                    t1_1.model,
                    t1_1.division,
                    t1_1.brand_name,
                    t1_1.item_description,
                    t1_1.current_item_num
                   FROM pos_reporting.lookup_stores t1_1
                     JOIN ( SELECT lookup_stores.prime_item_num,
                            max(lookup_stores.date_inserted::date) AS date_compare
                           FROM pos_reporting.lookup_stores
                          GROUP BY lookup_stores.prime_item_num) t2 ON t1_1.prime_item_num = t2.prime_item_num AND t1_1.date_inserted::date = t2.date_compare
                )
         SELECT DISTINCT ssa.id,
            ssa.pos_qty,
            ssa.pos_sales,
            ssa.curr_repl_instock,
            ssa.daily,
            COALESCE(sl.current_item_num::integer, ssa.prime_item_nbr) AS item_id,
            COALESCE(wmcbid.item_id, sl.item_id::text, pr.item_id) AS base_id,
            cbm.cat,
            cbm.sub_cat,
            COALESCE(sl.division, pr.division) AS division,
            ssa.retail_type_id,
            COALESCE(sl.item_description, pr.product_name, ssa.prime_item_desc) AS product_name,
            COALESCE(sl.model, pr.model::text) AS model,
            COALESCE(sl.brand_name, rs.brand_name) AS brand_name
           FROM ssa
             LEFT JOIN pr ON ssa.prime_item_nbr = pr.item_num
             LEFT JOIN cbm ON cbm.model = pr.model::text
             LEFT JOIN rs ON pr.item_id = rs.tool_id
             LEFT JOIN wmcbid ON wmcbid.gtin = rs.base_upc
             LEFT JOIN bid ON bid.tool_id::text = wmcbid.item_id
             LEFT JOIN bn ON bn.brand_name = rs.brand_name
             LEFT JOIN sl ON sl.prime_item_num = ssa.prime_item_nbr) t1
     LEFT JOIN wm_catalog2 w ON t1.item_id = w.item_num;


 WITH ssa AS (
         SELECT wm_stores_pos.id,
            wm_stores_pos.pos_qty,
            wm_stores_pos.pos_sales,
            wm_stores_pos.sale_date,
            wm_stores_pos.item_id::text AS item_id,
            wm_stores_pos.cat,
            wm_stores_pos.sub_cat,
            wm_stores_pos.division,
            wm_stores_pos.retail_type_id,
            wm_stores_pos.product_name,
            wm_stores_pos.model,
            wm_stores_pos.base_id,
            wm_stores_pos.brand_name
           FROM pos_reporting.wm_stores_pos
        ), d AS (
         SELECT divisions_view.division_id,
            divisions_view.division_name
           FROM power_bi.divisions_view
        ), tv AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), pnv AS (
         SELECT product_name_view_pbix.product_name,
            product_name_view_pbix.product_name_id
           FROM power_bi.product_name_view_pbix
        ), c AS (
         SELECT category_view.category_id,
            category_view.category_name,
            category_view.am_id
           FROM power_bi.category_view
        ), scv AS (
         SELECT sub_category_view.sub_cat_id,
            sub_category_view.sub_cat_name
           FROM power_bi.sub_category_view
        ), bid AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
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
        ), rt AS (
         SELECT retail_type.retail_type_id,
            retail_type.retail_type
           FROM power_bi.retail_type
        ), g AS (
         SELECT group_id_view.tool_id,
            group_id_view.group_id,
            group_id_view.collection_name,
            group_id_view.group_id_id,
            group_id_view.concat_gid_name
           FROM power_bi.group_id_view
        ), mv AS (
         SELECT model_view_pbix.model_name,
            model_view_pbix.model_id
           FROM power_bi.model_view_pbix
        )
 SELECT ssa.id,
    ssa.pos_qty,
    ssa.pos_sales,
    wmcal.wmcal_id,
    tv.tool_id_id,
    c.category_id,
    ssa.cat,
    scv.sub_cat_id,
    d.division_id,
    rt.retail_type_id,
    pnv.product_name_id,
    mv.model_id,
    bn.brand_id,
    bid.tool_id_id AS base_id_id
   FROM ssa
     LEFT JOIN tv ON tv.tool_id::text = ssa.item_id
     LEFT JOIN g ON g.tool_id::text = tv.tool_id::text
     LEFT JOIN c ON c.category_name = ssa.cat
     LEFT JOIN scv ON scv.sub_cat_name = ssa.sub_cat
     LEFT JOIN wmcal ON wmcal.date = ssa.sale_date
     LEFT JOIN d ON d.division_name = ssa.division
     LEFT JOIN rt ON ssa.retail_type_id = rt.retail_type_id
     LEFT JOIN mv ON mv.model_name::text = ssa.model
     LEFT JOIN pnv ON pnv.product_name::text = ssa.product_name
     LEFT JOIN bn ON bn.brand_name = ssa.brand_name
     LEFT JOIN bid ON bid.tool_id::text = ssa.base_id;