/*this is for wm pos data. the query contains all the links to dim tables but columns are dim columns not fact columns*/
 
WITH model_tool AS (
		select item_id;:text as item_id
		,model
		,division
		from clean_data.com_product_list

        ), pn AS (
         SELECT DISTINCT products_raw.product_name,
            products_raw.model
           FROM products_raw
        ), g AS (
         SELECT group_id_view.tool_id::text AS tool_id,
            group_id_view.group_id,
            group_id_view.collection_name,
            group_id_view.group_id_id,
            group_id_view.concat_gid_name
           FROM power_bi.group_id_view
        ), rs AS (
         SELECT rs1.id,
            rs1.tool_id,
            rs1.product_name,
            rs1.upc,
            tool_brand.brand_name,
            rs1.base_upc,
            rs1.sale_date,
            rs1.wm_week,
            rs1.units,
            rs1.sales,
            2 AS retail_type_id
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
        ), cbm AS (
         SELECT cat_by_model.model,
            cat_by_model.cat,
            cat_by_model.sub_cat,
            cat_by_model.cbm_id
           FROM cat_by_model
        ), c AS (
         SELECT category_view.category_id,
            category_view.category_name,
            category_view.am_id
           FROM power_bi.category_view
        ), tv AS (
         SELECT tool_id_view.tool_id,
            tool_id_view.tool_id_id
           FROM power_bi.tool_id_view
        ), rt AS (
         SELECT retail_type.retail_type_id,
            retail_type.retail_type
           FROM power_bi.retail_type
        ), wmc AS (
         SELECT wm_catalog2.item_num,
            wm_catalog2.item_id,
            "left"(wm_catalog2.gtin, 13) AS gtin,
            wm_catalog2.item_description
           FROM wm_catalog2
        ), mv AS (
         SELECT model_view_pbix.model_name,
            model_view_pbix.model_id
           FROM power_bi.model_view_pbix
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
        ), d AS (
         SELECT divisions_view.division_id,
            divisions_view.division_name
           FROM power_bi.divisions_view
        )
        ,lookup as (/*lookup table is to find missing model and item ids for pos. also to omit duplicated done in the case statment for model*/	
			select t1.item_id, model, division, product_name
			from pos_reporting.lookup_com t1
			 join
			(--finding most recent record for an inserted item id
				select item_id, max(date_inserted) as date_compare 
				from pos_reporting.lookup_com
				group by item_id
			) t2
			on t1.item_id = t2.item_id
			and date_inserted = date_compare
		)
 SELECT DISTINCT rs.id,
    coalesce(lookup.model,model_tool.model) as model,
    coalesce(lookup.division,model_tool.division) as division,
    rs.tool_id,
    coalesce(lookup.product_name,pn.product_name, rs.product_name) as product_name,
    g.group_id,
    cbm.cat,
    coalesce(wmc.item_id, rs.tool_id) AS base_id,
    rs.sale_date,
    rs.wm_week,
    rs.brand_name,
    rs.base_upc,
    rs.units,
    rs.sales
   FROM rs
     LEFT JOIN model_tool ON model_tool.item_id::text = rs.tool_id
     LEFT JOIN pn ON pn.model = model_tool.model::text
     LEFT JOIN g ON g.tool_id = rs.tool_id
     LEFT JOIN cbm ON cbm.model = model_tool.model::text
     LEFT JOIN c ON c.category_name = cbm.cat
     LEFT JOIN wmc ON rs.base_upc = wmc.gtin
     LEFT JOIN wmcal ON wmcal.date = rs.sale_date
     LEFT JOIN bn ON bn.brand_name = rs.brand_name
     LEFT JOIN d ON d.division_name = model_tool.division::text
     LEFT JOIN lookup on lookup.item_id = rs.tool_id


;
