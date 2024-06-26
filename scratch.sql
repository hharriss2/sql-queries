with w AS (
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
        )