 --used to be clean_data.stores_product_list_view . replaced with new logic
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
                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])))) OR (products_raw.model IN ( SELECT DISTINCT w_1.supplier_stock_id
                   FROM wm_catalog2 w_1
                  WHERE w_1.supplier_stock_id <> ALL (ARRAY['WM3921E'::text, 'WM2906WJYF-DC'::text])))) AND products_raw.model !~~ '%OLD%'::text AND products_raw.product_name !~~ '%Displ%'::text AND products_raw.model !~~ '%MOV%'::text
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
                    ELSE w_1.item_id
                END AS item_id,
            COALESCE(dupe_lookup.upc, w_1.upc) AS upc,
            w_1.supplier_stock_id
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
                  WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s.tool_id::text <> '0'::text) model_tool_1 ON model_tool_1.tool_id::text = w_1.item_id
             LEFT JOIN ( SELECT dupe_store_records.item_num,
                    dupe_store_records.item_description,
                    dupe_store_records.item_id,
                    dupe_store_records.upc
                   FROM ( SELECT DISTINCT w_2.item_num,
                            w_2.item_description,
                            w_2.item_id,
                            w_2.upc
                           FROM wm_catalog2 w_2
                          WHERE (w_2.item_description IN ( SELECT t1.prime_item_desc
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
  WHERE recent_item_desc_1.date_compare = all_item_nbrs_1.daily) t1
                                  GROUP BY t1.prime_item_desc
                                 HAVING count(t1.prime_item_desc) > 1))) dupe_store_records
                  WHERE (dupe_store_records.item_id IN ( SELECT DISTINCT s.tool_id
                           FROM ( SELECT ships.model,
                                    max(ships.date_shipped) AS date_compare
                                   FROM ships_schema.ships
                                  GROUP BY ships.model) ship_model
                             JOIN ships_schema.ships s ON s.model::text = ship_model.model::text
                          WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s.tool_id::text <> '0'::text)) AND dupe_store_records.item_num <> 569020027) dupe_lookup ON dupe_lookup.item_description = w_1.item_description
             LEFT JOIN ( SELECT DISTINCT s.tool_id,
                    ship_upc.upc
                   FROM ( SELECT ships.upc,
                            max(ships.date_shipped) AS date_compare
                           FROM ships_schema.ships
                          GROUP BY ships.upc) ship_upc
                     JOIN ships_schema.ships s ON s.upc::text = ship_upc.upc::text
                  WHERE 1 = 1 AND s.date_shipped = ship_upc.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s.tool_id::text <> '0'::text) tool_upc ON COALESCE(tool_upc.tool_id::text = dupe_lookup.item_id, tool_upc.tool_id::text = model_tool_1.tool_id::text, tool_upc.tool_id::text = w_1.item_id)
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
                          WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND ships.tool_id::text <> ''::text AND ships.tool_id::text <> '0'::text
                          GROUP BY ships.model) model_tool_older ON s_1.model::text = model_tool_older.model::text
                  WHERE 1 = 1 AND s_1.date_shipped = model_tool_older.date_compare AND s_1.tool_id::text <> '0'::text AND s_1.tool_id::text <> ''::text) old_tool ON s.model::text = old_tool.model::text
          WHERE 1 = 1 AND s.date_shipped = ship_model.date_compare AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text])) AND s.tool_id::text <> '0'::text
        ), model_upc AS (
         SELECT s.model,
            s.upc,
            max(s.date_shipped) AS date_compare
           FROM ships_schema.ships s
             JOIN ( SELECT ships.upc,
                    max(ships.date_shipped) AS date_compare2
                   FROM ships_schema.ships
                  WHERE 1 = 1 AND (ships.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
                  GROUP BY ships.upc) max_model ON s.upc::text = max_model.upc::text
          WHERE 1 = 1 AND s.upc::text ~~ '0%'::text AND max_model.date_compare2 = s.date_shipped AND (s.retailer::text = ANY (ARRAY['Walmart.com'::character varying::text, 'Walmart Stores'::character varying::text]))
          GROUP BY s.model, s.upc
        )
 SELECT DISTINCT w.item_num,
        CASE
            WHEN model_tool.tool_id::text = ''::text THEN w.item_id
            WHEN model_tool.tool_id::text = '\N'::text THEN w.item_id
            WHEN model_tool.tool_id IS NOT NULL THEN model_tool.tool_id::text
            ELSE w.item_id
        END AS item_id,
    COALESCE(model_upc.model, p.model::character varying) AS model,
    p.product_name,
    p.division,
        CASE
            WHEN w.upc IS NOT NULL THEN w.upc
            WHEN w.upc IS NULL THEN p.upc
            WHEN p.upc IS NULL THEN p.base_upc
            ELSE NULL::text
        END AS upc
   FROM p
     LEFT JOIN w ON COALESCE(p.base_upc = w.upc, p.upc = w.upc, p.model = w.supplier_stock_id)
     LEFT JOIN model_tool ON model_tool.model::text = p.model
     LEFT JOIN model_upc ON COALESCE(p.base_upc = model_upc.upc::text, p.upc = model_upc.upc::text)
  WHERE 1 = 1 AND (p.retailer_id = ANY (ARRAY[1, 4]));