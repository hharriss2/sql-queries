 WITH model_tool AS (
         WITH pr AS (
                 SELECT DISTINCT COALESCE(rs.item_id::text,
                        CASE
                            WHEN model_tool_1.tool_id::text = ''::text THEN w.item_id
                            WHEN w.upc::text <> model_tool_1.upc THEN w.item_id
                            WHEN model_tool_1.tool_id IS NOT NULL THEN model_tool_1.tool_id::text
                            ELSE w.item_id
                        END) AS item_id,
                    COALESCE(w.ships_model,
                        CASE
                            WHEN model_tool_1.model::text = pr_com.model THEN model_tool_1.model::text
                            WHEN model_tool_1.tool_id::text = ''::text THEN pr_com.model
                            WHEN model_tool_1.model IS NOT NULL THEN model_tool_1.model::text
                            WHEN model_tool_1.model IS NULL THEN pr_com.model
                            ELSE p.model
                        END::character varying, p.model::character varying) AS model,
                    p.division,
                    model_tool_1.date_compare
                   FROM products_raw p
                     LEFT JOIN ( SELECT DISTINCT w_1.item_id,
                            w2.item_id AS w_2_item_id,
                            s.upc AS s_upc,
                            w_1.upc AS w_upc,
                            COALESCE(s.upc, w_1.upc::character varying) AS upc,
                            s.model AS ships_model
                           FROM wm_catalog2 w_1
                             LEFT JOIN ( SELECT DISTINCT s_1.model,
CASE
 WHEN model_upc.tool_id::text = ''::text THEN s_1.tool_id
 WHEN model_upc.upc::text = s_1.upc::text THEN model_upc.tool_id
 ELSE s_1.tool_id
END AS tool_id,
                                    model_upc.upc
                                   FROM ships_schema.ships s_1
                                     JOIN ( SELECT s_2.model,
    s_2.upc,
    s_2.tool_id,
    max(s_2.date_shipped) AS date_compare
   FROM ships_schema.ships s_2
     JOIN ( SELECT ships.model,
      max(ships.date_shipped) AS date_compare2
     FROM ships_schema.ships
    WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
    GROUP BY ships.model) max_model ON s_2.model::text = max_model.model::text
     JOIN ( SELECT ships.tool_id,
      max(ships.date_shipped) AS date_compare3
     FROM ships_schema.ships
    GROUP BY ships.tool_id) max_tool_id ON s_2.tool_id::text = max_tool_id.tool_id::text
  WHERE 1 = 1 AND s_2.upc::text ~~ '0%'::text AND max_model.date_compare2 = s_2.date_shipped AND max_tool_id.date_compare3 = max_model.date_compare2 AND (s_2.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
  GROUP BY s_2.model, s_2.upc, s_2.tool_id) model_upc ON s_1.model::text = model_upc.model::text
                                  WHERE 1 = 1 AND (s_1.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s_1.upc::text ~~ '0%'::text) s ON w_1.item_id = s.tool_id::text
                             LEFT JOIN wm_catalog2 w2 ON w2.upc = s.upc::text) w ON p.upc = w.upc::text
                     LEFT JOIN ( SELECT products_raw.model,
                            products_raw.upc,
                            products_raw.base_upc
                           FROM products_raw
                          WHERE products_raw.retailer_id = 4) prcom ON p.model = prcom.model
                     LEFT JOIN ( SELECT DISTINCT s.model,
                                CASE
                                    WHEN s.tool_id::text = ''::text THEN old_tool.tool_id
                                    ELSE s.tool_id
                                END AS tool_id,
                            s.division,
                            COALESCE(w_1.upc, s.upc::text) AS upc,
                            ship_model.date_compare
                           FROM ( SELECT ships.model,
                                    max(ships.date_shipped) AS date_compare
                                   FROM ships_schema.ships
                                  WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
                                  GROUP BY ships.model) ship_model
                             JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                             JOIN ( SELECT DISTINCT s_1.model,
                                    s_1.tool_id
                                   FROM ships_schema.ships s_1
                                     JOIN ( SELECT DISTINCT ships.model,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND ships.tool_id::text <> ''::text AND ships.tool_id::text <> '0'::text
  GROUP BY ships.model) model_tool_older ON s_1.model::text = model_tool_older.model::text
                                  WHERE 1 = 1 AND s_1.date_shipped = model_tool_older.date_compare AND s_1.tool_id::text <> '0'::text AND s_1.tool_id::text <> ''::text) old_tool ON s.model::text = old_tool.model::text
                             LEFT JOIN ( SELECT wm_catalog2.item_id,
                                    wm_catalog2.upc
                                   FROM wm_catalog2) w_1 ON s.tool_id::text = w_1.item_id
                          WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s.tool_id::text <> '0'::text) model_tool_1 ON model_tool_1.model::text = p.model
                     LEFT JOIN ( SELECT DISTINCT products_raw.model,
                            products_raw.upc
                           FROM products_raw
                          WHERE products_raw.retailer_id = 4) pr_com ON p.upc = pr_com.upc
                     LEFT JOIN retail_link_pos rs ON w.item_id = rs.item_id::text
                  WHERE 1 = 1 AND (p.retailer_id = ANY (ARRAY[1, 4])) AND p.model !~~ '%OLD%'::text AND p.product_name !~~ '%Displ%'::text
                ), count_pr AS (
                 SELECT count(t1.item_id) AS count,
                    t1.item_id
                   FROM ( SELECT DISTINCT COALESCE(rs.item_id::text,
                                CASE
                                    WHEN model_tool_1.tool_id::text = ''::text THEN w.item_id
                                    WHEN w.upc::text <> model_tool_1.upc THEN w.item_id
                                    WHEN model_tool_1.tool_id IS NOT NULL THEN model_tool_1.tool_id::text
                                    ELSE w.item_id
                                END) AS item_id,
                            COALESCE(w.ships_model,
                                CASE
                                    WHEN model_tool_1.model::text = pr_com.model THEN model_tool_1.model::text
                                    WHEN model_tool_1.tool_id::text = ''::text THEN pr_com.model
                                    WHEN model_tool_1.model IS NOT NULL THEN model_tool_1.model::text
                                    WHEN model_tool_1.model IS NULL THEN pr_com.model
                                    ELSE p.model
                                END::character varying, p.model::character varying) AS model,
                            p.division,
                            model_tool_1.date_compare
                           FROM products_raw p
                             LEFT JOIN ( SELECT DISTINCT w_1.item_id,
                                    w2.item_id AS w_2_item_id,
                                    s.upc AS s_upc,
                                    w_1.upc AS w_upc,
                                    COALESCE(s.upc, w_1.upc::character varying) AS upc,
                                    s.model AS ships_model
                                   FROM wm_catalog2 w_1
                                     LEFT JOIN ( SELECT DISTINCT s_1.model,
  CASE
   WHEN model_upc.tool_id::text = ''::text THEN s_1.tool_id
   WHEN model_upc.upc::text = s_1.upc::text THEN model_upc.tool_id
   ELSE s_1.tool_id
  END AS tool_id,
    model_upc.upc
   FROM ships_schema.ships s_1
     JOIN ( SELECT s_2.model,
      s_2.upc,
      s_2.tool_id,
      max(s_2.date_shipped) AS date_compare
     FROM ships_schema.ships s_2
       JOIN ( SELECT ships.model,
        max(ships.date_shipped) AS date_compare2
       FROM ships_schema.ships
      WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
      GROUP BY ships.model) max_model ON s_2.model::text = max_model.model::text
       JOIN ( SELECT ships.tool_id,
        max(ships.date_shipped) AS date_compare3
       FROM ships_schema.ships
      GROUP BY ships.tool_id) max_tool_id ON s_2.tool_id::text = max_tool_id.tool_id::text
    WHERE 1 = 1 AND s_2.upc::text ~~ '0%'::text AND max_model.date_compare2 = s_2.date_shipped AND max_tool_id.date_compare3 = max_model.date_compare2 AND (s_2.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
    GROUP BY s_2.model, s_2.upc, s_2.tool_id) model_upc ON s_1.model::text = model_upc.model::text
  WHERE 1 = 1 AND (s_1.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s_1.upc::text ~~ '0%'::text) s ON w_1.item_id = s.tool_id::text
                                     LEFT JOIN wm_catalog2 w2 ON w2.upc = s.upc::text) w ON p.upc = w.upc::text
                             LEFT JOIN ( SELECT products_raw.model,
                                    products_raw.upc,
                                    products_raw.base_upc
                                   FROM products_raw
                                  WHERE products_raw.retailer_id = 4) prcom ON p.model = prcom.model
                             LEFT JOIN ( SELECT DISTINCT s.model,
CASE
 WHEN s.tool_id::text = ''::text THEN old_tool.tool_id
 ELSE s.tool_id
END AS tool_id,
                                    s.division,
                                    COALESCE(w_1.upc, s.upc::text) AS upc,
                                    ship_model.date_compare
                                   FROM ( SELECT ships.model,
    max(ships.date_shipped) AS date_compare
   FROM ships_schema.ships
  WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
  GROUP BY ships.model) ship_model
                                     JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                                     JOIN ( SELECT DISTINCT s_1.model,
    s_1.tool_id
   FROM ships_schema.ships s_1
     JOIN ( SELECT DISTINCT ships.model,
      max(ships.date_shipped) AS date_compare
     FROM ships_schema.ships
    WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND ships.tool_id::text <> ''::text AND ships.tool_id::text <> '0'::text
    GROUP BY ships.model) model_tool_older ON s_1.model::text = model_tool_older.model::text
  WHERE 1 = 1 AND s_1.date_shipped = model_tool_older.date_compare AND s_1.tool_id::text <> '0'::text AND s_1.tool_id::text <> ''::text) old_tool ON s.model::text = old_tool.model::text
                                     LEFT JOIN ( SELECT wm_catalog2.item_id,
    wm_catalog2.upc
   FROM wm_catalog2) w_1 ON s.tool_id::text = w_1.item_id
                                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s.tool_id::text <> '0'::text) model_tool_1 ON model_tool_1.model::text = p.model
                             LEFT JOIN ( SELECT DISTINCT products_raw.model,
                                    products_raw.upc
                                   FROM products_raw
                                  WHERE products_raw.retailer_id = 4) pr_com ON p.upc = pr_com.upc
                             LEFT JOIN retail_link_pos rs ON w.item_id = rs.item_id::text
                          WHERE 1 = 1 AND (p.retailer_id = ANY (ARRAY[1, 4])) AND p.model !~~ '%OLD%'::text AND p.product_name !~~ '%Displ%'::text) t1
                  GROUP BY t1.item_id
                 HAVING count(t1.item_id) > 1
                )
         SELECT pr.item_id,
            pr.model,
            pr.division,
            pr.date_compare
           FROM pr
          WHERE NOT (pr.item_id IN ( SELECT DISTINCT count_pr.item_id
                   FROM count_pr))
        )
 SELECT model_tool.item_id::bigint AS item_id,
    model_tool.model,
    model_tool.division
   FROM model_tool
  WHERE model_tool.item_id ~ '^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$'::text;