/*this is for wm pos data. the query contains all the links to dim tables but columns are dim columns not fact columns*/
create or replace view pos_reporting.wm_com_pos as (
SELECT t1.id,
   t1.model,
   t1.division,
   t1.tool_id,
   t1.product_name,
   t1.group_id_id,
   cbm.cat,
   cbm.cbm_id,
   t1.base_id,
   t1.sale_date,
   t1.wm_week,
   t1.brand_name,
   t1.base_upc,
   t1.item_type,
   t1.units,
   t1.sales,
   t1.is_put
FROM (
WITH model_tool AS (
		select item_id::text as item_id
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
            tpt.product_name,
            rs1.upc,
            rs1.base_upc,
            case when tpt.product_name like '%Queer%'
            	then 'Queer Eye'
            	when tpt.product_name like '%Cosmo%'
            	then 'CosmoLiving by Cosmopolitan'
            	else tbt.brand_name 
            	end as brand_name ,
            rs1.item_type,
            rs1.sale_date,
            rs1.wm_week,
            rs1.units,
            rs1.sales,
            rs1.is_put,
            2 AS retail_type_id
           FROM pos_reporting.retail_sales rs1
             LEFT JOIN lookups.tool_brand_tbl tbt 
             ON tbt.tool_id = rs1.tool_id
             left JOIN lookups.tool_pn_tbl tpt
             on tpt.tool_id = rs1.tool_id
              	
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
			select t1.item_id, model, division, product_name, current_item_id
			from pos_reporting.lookup_com t1
			 join
			(--finding most recent record for an inserted item id
				select item_id, max(date_inserted) as date_compare 
				from pos_reporting.lookup_com
				group by item_id
			) t2
			on t1.item_id = t2.item_id
			and date_inserted = date_compare
		),cb as (
			select base_id::text, group_id
			from lookups.current_base_id
		),pf_filter as 
			(
			select * 
			from power_bi.promo_funding_pos_filter
			)
 SELECT DISTINCT rs.id,
    coalesce(lookup.model,model_tool.model) as model,
    coalesce(lookup.division,model_tool.division) as division,
    coalesce(lookup.current_item_id,rs.tool_id) as tool_id,
    coalesce(pn.product_name,lookup.product_name,rs.product_name) as product_name,
    g.group_id_id,
    coalesce(cb.base_id,wmc.item_id, rs.tool_id) AS base_id,
    rs.sale_date,
    rs.wm_week,
    rs.brand_name,
    rs.base_upc,
    rs.item_type,
    rs.units,
    rs.sales,
    rs.is_put
   FROM rs
     LEFT JOIN model_tool ON model_tool.item_id::text = rs.tool_id
     LEFT JOIN pn ON pn.model = model_tool.model::text
     LEFT JOIN g ON g.tool_id = rs.tool_id
     left join cb on cb.group_id = g.group_id
     LEFT JOIN wmc ON rs.base_upc = wmc.gtin
     LEFT JOIN wmcal ON wmcal.date = rs.sale_date
     LEFT JOIN bn ON bn.brand_name = rs.brand_name
     LEFT JOIN d ON d.division_name = model_tool.division::text
     LEFT JOIN lookup on lookup.item_id = rs.tool_id
) t1
     LEFT JOIN cat_by_model cbm ON cbm.model = t1.model

);


--actual view used in postgres
  create or replace view pos_reporting.wm_com_pos as 
 (
 SELECT t1.id,
    t1.model,
    t1.division,
    t1.tool_id,
    t1.product_name,
    t1.group_id_id,
    cbm.cat,
    cbm.cbm_id,
    t1.base_id,
    t1.sale_date,
    t1.wm_week,
    t1.brand_name,
    t1.base_upc,
    t1.item_type,
    t1.units,
    t1.sales,
    t1.is_put
   FROM ( 
WITH model_tool AS 
(
 SELECT item_id::text AS item_id
   ,model
   ,division
   FROM clean_data.master_com_list

)
, pn AS 
(
                 SELECT DISTINCT products_raw.product_name,
                    products_raw.model
                   FROM products_raw
                  WHERE products_raw.retailer_id = ANY (ARRAY[1, 4])
)
, g AS 
(
SELECT group_id_view.tool_id::text AS tool_id,
group_id_view.group_id,
group_id_view.collection_name,
group_id_view.group_id_id,
group_id_view.concat_gid_name
FROM power_bi.group_id_view
)
, rs AS 
(
 SELECT rs1.id,
    rs1.tool_id,
    tpt.product_name,
    rs1.upc,
    rs1.base_upc,
        CASE
            WHEN tpt.product_name ~~ '%Queer%'::text THEN 'Queer Eye'::text
            WHEN tpt.product_name ~~ '%Cosmo%'::text THEN 'CosmoLiving by Cosmopolitan'::text
            ELSE tbt.brand_name
        END AS brand_name,
    rs1.item_type,
    rs1.sale_date,
    rs1.wm_week,
    rs1.units,
    rs1.sales,
    rs1.is_put,
    2 AS retail_type_id
   FROM pos_reporting.retail_sales rs1
     LEFT JOIN lookups.tool_brand_tbl tbt ON tbt.tool_id = rs1.tool_id
     LEFT JOIN lookups.tool_pn_tbl tpt ON tpt.tool_id = rs1.tool_id
)
, cbm AS 
(
                 SELECT cat_by_model.model,
                    cat_by_model.cat,
                    cat_by_model.sub_cat,
                    cat_by_model.cbm_id
                   FROM cat_by_model
)
, c AS 
(
 SELECT category_view.category_id,
    category_view.category_name,
    category_view.am_id
   FROM power_bi.category_view
)
, tv AS (
 SELECT tool_id_view.tool_id,
    tool_id_view.tool_id_id
   FROM power_bi.tool_id_view
)
, rt AS 
(
 SELECT retail_type.retail_type_id,
    retail_type.retail_type
   FROM power_bi.retail_type
)
, wmc AS 
(
 SELECT wm_catalog2.item_num,
    wm_catalog2.item_id,
    "left"(wm_catalog2.gtin, 13) AS gtin,
    wm_catalog2.item_description
   FROM wm_catalog2
)
, mv AS 
(
SELECT model_view_pbix.model_name,
model_view_pbix.model_id
FROM power_bi.model_view_pbix
)
, wmcal AS 
(
 SELECT wm_calendar_view.wmcal_id,
    wm_calendar_view.date,
    wm_calendar_view.wm_week,
    wm_calendar_view.wm_year,
    wm_calendar_view.wm_date,
    wm_calendar_view.month
   FROM power_bi.wm_calendar_view
)
, bn AS 
(
SELECT brand_name.brand_id,
brand_name.brand_name
FROM power_bi.brand_name
)
, d AS 
(
SELECT divisions_view.division_id,
divisions_view.division_name
FROM power_bi.divisions_view
)
, lookup AS 
(
 SELECT t1_1.item_id,
    t1_1.model,
    t1_1.division,
    t1_1.product_name,
    t1_1.current_item_id
   FROM pos_reporting.lookup_com t1_1
     JOIN ( SELECT lookup_com.item_id,
            max(lookup_com.date_inserted) AS date_compare
           FROM pos_reporting.lookup_com
          GROUP BY lookup_com.item_id) t2 ON t1_1.item_id = t2.item_id AND t1_1.date_inserted = t2.date_compare
)
, cb AS 
(
 SELECT current_base_id.base_id::text AS base_id,
    current_base_id.group_id
   FROM lookups.current_base_id
)
,pf_filter AS 
(
 SELECT promo_funding_pos_filter.pf_id,
    promo_funding_pos_filter.tool_id,
    promo_funding_pos_filter.start_date,
    promo_funding_pos_filter.end_date,
    promo_funding_pos_filter.promo_type
   FROM power_bi.promo_funding_pos_filter
)
 SELECT DISTINCT rs.id,
    COALESCE(lookup.model, model_tool.model) AS model,
    COALESCE(lookup.division, model_tool.division) AS division,
    COALESCE(lookup.current_item_id, rs.tool_id) AS tool_id,
    COALESCE(lookup.product_name,rs.product_name, pn.product_name) AS product_name,
    g.group_id_id,
    COALESCE(cb.base_id, wmc.item_id, rs.tool_id) AS base_id,
    rs.sale_date,
    rs.wm_week,
    rs.brand_name,
    rs.base_upc,
    rs.item_type,
    rs.units,
    rs.sales,
    rs.is_put
   FROM rs
     LEFT JOIN model_tool ON model_tool.item_id = rs.tool_id
     LEFT JOIN pn ON pn.model = model_tool.model
     LEFT JOIN g ON g.tool_id = rs.tool_id
     LEFT JOIN cb ON cb.group_id = g.group_id
     LEFT JOIN wmc ON rs.base_upc = wmc.gtin
     LEFT JOIN wmcal ON wmcal.date = rs.sale_date
     LEFT JOIN bn ON bn.brand_name = rs.brand_name
     LEFT JOIN d ON d.division_name = model_tool.division
     LEFT JOIN lookup ON lookup.item_id = rs.tool_id) t1
LEFT JOIN cat_by_model cbm ON cbm.model = t1.model
);