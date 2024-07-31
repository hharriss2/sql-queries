 SELECT t1.group_id AS "Group ID",
    t1.collection_name AS "Collection Name",
    t1.category_name AS "Category",
    t1.account_manager AS "Account Manager",
    t1.l4_units AS "Last 4 Average Units Sold",
    t1.l52_units AS "Last 52 Average Units Sold",
    t1.l4_52_change::integer || '%'::text AS "Last 4 % Change Vs Last 52"
   FROM ( SELECT DISTINCT c.category_name,
            t1_1.group_id,
            t1_1.collection_name,
            a.account_manager,
            t1_1.l4_units,
            t2.l52_units,
                CASE
                    WHEN t2.l52_units <= 0::numeric THEN NULL::numeric
                    ELSE (t1_1.l4_units - t2.l52_units) / t2.l52_units * 100::numeric
                END AS l4_52_change
           FROM ( SELECT l4_units_sold.group_id,
                    l4_units_sold.collection_name,
                    l4_units_sold.l4_units,
                    l4_units_sold.tool_id
                   FROM ( SELECT g.group_id,
                            g.collection_name,
                            (sum(rs.units)::numeric / 4::numeric(10,2))::numeric(10,2) AS l4_units,
                            max(rs.tool_id::integer) AS tool_id
                           FROM pos_reporting.retail_sales rs
                             LEFT JOIN group_ids g ON rs.tool_id::integer = g.tool_id
                          WHERE (rs.wm_week IN ( SELECT DISTINCT retail_sales.wm_week
                                   FROM pos_reporting.retail_sales
                                  WHERE retail_sales.wm_week <> (( SELECT max(retail_sales_1.wm_week) AS max
   FROM pos_reporting.retail_sales retail_sales_1))
                                  ORDER BY retail_sales.wm_week DESC
                                 LIMIT 4))
                          GROUP BY g.group_id, g.collection_name) l4_units_sold
                  WHERE l4_units_sold.l4_units > 0::numeric) t1_1
             LEFT JOIN ( SELECT l52_units_sold.group_id,
                    l52_units_sold.l52_units
                   FROM ( SELECT g.group_id,
                            (sum(rs.units)::numeric / count(DISTINCT rs.wm_week)::numeric(10,2))::numeric(10,2) AS l52_units
                           FROM pos_reporting.retail_sales rs
                             LEFT JOIN group_ids g ON rs.tool_id::integer = g.tool_id
                          WHERE (rs.wm_week IN ( SELECT DISTINCT retail_sales.wm_week
                                   FROM pos_reporting.retail_sales
                                  WHERE retail_sales.wm_week <> (( SELECT max(retail_sales_1.wm_week) AS max
   FROM pos_reporting.retail_sales retail_sales_1))
                                  ORDER BY retail_sales.wm_week DESC
                                 LIMIT 52)) AND rs.units > 0
                          GROUP BY g.group_id) l52_units_sold
                  WHERE l52_units_sold.l52_units > 0::numeric) t2 ON t1_1.group_id = t2.group_id
             LEFT JOIN clean_data.master_com_list mcl ON mcl.item_id = t1_1.tool_id
             LEFT JOIN cat_by_model cbm ON mcl.model = cbm.model
             LEFT JOIN category c ON c.category_name = cbm.cat
             LEFT JOIN account_manager a ON c.am_id = a.account_manager_id
             LEFT JOIN products_raw p ON cbm.model = p.model
          WHERE 1 = 1 AND ((t1_1.group_id IN ( SELECT group_ids.group_id
                   FROM group_ids
                  WHERE (group_ids.tool_id IN ( SELECT DISTINCT ic.tool_id::integer AS tool_id
                           FROM item_class ic
                          WHERE ic.class = 'A'::text)))) OR cbm.cat = 'Mattresses'::text) AND t2.l52_units >= 15::numeric AND ((t1_1.l4_units - t2.l52_units) / t2.l52_units) < '-0.10'::numeric) t1;