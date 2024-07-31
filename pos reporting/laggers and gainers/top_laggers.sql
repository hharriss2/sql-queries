 SELECT t1.tool_id AS "Tool ID",
    t1.group_id AS "Group ID",
    t1.model AS "Model",
    t1.available AS "Is Available?",
    t1.product_name AS "Product Name",
    t1.category_name AS "Category",
    t1.account_manager AS "Account Manager",
    t1.l4_units AS "Last 4 Average Units Sold",
    t1.l52_units AS "Last 52 Average Units Sold",
    t1.l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
   FROM ( SELECT DISTINCT t1_1.tool_id,
                CASE
                    WHEN mrs.available = true THEN 'Available'::text
                    WHEN mrs.available = false THEN 'Unavailable'::text
                    ELSE NULL::text
                END AS available,
            model_tool.model,
            p.product_name,
            c.category_name,
            g.group_id,
            a.account_manager,
            t1_1.l4_units,
            t2.l52_units,
                CASE
                    WHEN t2.l52_units <= 0::numeric THEN NULL::numeric
                    ELSE (t1_1.l4_units - t2.l52_units) / t2.l52_units * 100::numeric
                END AS l4_52_change
           FROM ( SELECT l4_units_sold.tool_id::integer AS tool_id,
                    l4_units_sold.l4_units
                   FROM ( SELECT rs.tool_id,
                            (sum(rs.units)::numeric / 4::numeric(10,2))::numeric(10,2) AS l4_units
                           FROM pos_reporting.retail_sales rs
                          WHERE (rs.wm_week IN ( SELECT DISTINCT retail_sales.wm_week
                                   FROM pos_reporting.retail_sales
                                  WHERE retail_sales.wm_week <> (( SELECT max(retail_sales_1.wm_week) AS max
   FROM pos_reporting.retail_sales retail_sales_1))
                                  ORDER BY retail_sales.wm_week DESC
                                 LIMIT 4))
                          GROUP BY rs.tool_id) l4_units_sold
                  WHERE l4_units_sold.l4_units > 0::numeric) t1_1
             LEFT JOIN ( SELECT l52_units_sold.tool_id::integer AS tool_id,
                    l52_units_sold.l52_units
                   FROM ( SELECT rs.tool_id,
                            (sum(rs.units)::numeric / count(DISTINCT rs.wm_week)::numeric(10,2))::numeric(10,2) AS l52_units
                           FROM pos_reporting.retail_sales rs
                          WHERE (rs.wm_week IN ( SELECT DISTINCT retail_sales.wm_week
                                   FROM pos_reporting.retail_sales
                                  WHERE retail_sales.wm_week <> (( SELECT max(retail_sales_1.wm_week) AS max
   FROM pos_reporting.retail_sales retail_sales_1))
                                  ORDER BY retail_sales.wm_week DESC
                                 LIMIT 52)) AND rs.units > 0
                          GROUP BY rs.tool_id) l52_units_sold
                  WHERE l52_units_sold.l52_units > 0::numeric) t2 ON t1_1.tool_id = t2.tool_id
             LEFT JOIN ( SELECT master_com_list.model,
                    master_com_list.item_id AS tool_id
                   FROM clean_data.master_com_list) model_tool ON model_tool.tool_id = t1_1.tool_id
             LEFT JOIN cat_by_model cbm ON model_tool.model = cbm.model
             LEFT JOIN category c ON c.category_name = cbm.cat
             LEFT JOIN account_manager a ON c.am_id = a.account_manager_id
             LEFT JOIN scrape_data.most_recent_scrape mrs ON mrs.item_id = model_tool.tool_id
             LEFT JOIN products_raw p ON cbm.model = p.model
             LEFT JOIN group_ids g ON g.tool_id = t1_1.tool_id
          WHERE 1 = 1 AND ((t1_1.tool_id IN ( SELECT DISTINCT ic.tool_id::integer AS tool_id
                   FROM item_class ic
                  WHERE ic.class = 'A'::text)) OR cbm.cat = 'Mattresses'::text) AND model_tool.model IS NOT NULL AND t2.l52_units >= 15::numeric AND ((t1_1.l4_units - t2.l52_units) / t2.l52_units) < '-0.10'::numeric) t1;