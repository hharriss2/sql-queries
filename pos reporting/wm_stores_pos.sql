--updated june 20, 2024. 
--some final clean up to wm stores pos data & will be used as the base for the fact table
create or replace view pos_reporting.wm_stores_pos as 
(
 SELECT t1.id,
    t1.pos_qty,
    t1.pos_sales,
    t1.curr_repl_instock,
    t1.daily AS sale_date,
    COALESCE(t1.item_id, w.item_num)::integer AS item_id,
    cbm.cbm_id,
    c.am_id,
    t1.division,
    t1.retail_type_id,
    t1.product_name,
    t1.model,
    t1.base_id,
    t1.brand_name,
    stat.id AS item_stat_id
   FROM ( 
        WITH  ssa as 
                (
                select *
                	,1 as retail_type_id
                from pos_reporting.store_sales
                )
                ,wmcbid AS -- wlamart catalog base id find
                ( -- find the gtin for the wm item id to join on base id.
                 SELECT DISTINCT wm_catalog2.item_id,
                    wm_catalog2.upc,
                    "left"(wm_catalog2.gtin, 13) AS gtin
                   FROM wm_catalog2
                )
                , d AS (
                 SELECT divisions_view.division_id,
                    divisions_view.division_name
                   FROM power_bi.divisions_view
                )
                , cbm AS (
                 SELECT cat_by_model.model,
                    cat_by_model.cat,
                    cat_by_model.sub_cat,
                    cat_by_model.cbm_id,
                    cat_by_model.sams_only,
                    cat_by_model.is_top_cat
                   FROM cat_by_model
                )
                , tv AS (
                 SELECT tool_id_view.tool_id,
                    tool_id_view.tool_id_id
                   FROM power_bi.tool_id_view
                )
                , pr AS (
                 SELECT stores_product_list.item_num,
                    stores_product_list.item_id,
                    stores_product_list.model,
                    stores_product_list.product_name,
                    stores_product_list.division,
                    stores_product_list.upc
                   FROM clean_data.stores_product_list
                )
                , rs AS 
                (
                 select
                    mcl.item_id::text as tool_id
                    ,tbrand.brand_name
                    ,tbupc.base_upc
                from clean_data.master_com_list mcl
                left join lookups.tool_brand tbrand
                on mcl.item_id = tbrand.tool_id::bigint
                left join lookups.tool_base_upc tbupc
                on mcl.item_id = tbupc.tool_id::bigint

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
                    group_id_view.concat_gid_name,
                    group_id_view.in_production
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
            COALESCE(sl.item_id::text, wmcbid.item_id, pr.item_id) AS base_id,
            cbm_1.cat,
            cbm_1.sub_cat,
            COALESCE(sl.division, pr.division) AS division,
            ssa.retail_type_id,
            COALESCE(sl.item_description, pr.product_name, ssa.prime_item_desc) AS product_name,
            COALESCE(sl.model, pr.model) AS model,
            COALESCE(sl.brand_name, rs.brand_name) AS brand_name
           FROM ssa
             LEFT JOIN pr ON ssa.prime_item_nbr = pr.item_num
             LEFT JOIN cbm cbm_1 ON cbm_1.model = pr.model
             LEFT JOIN rs ON pr.item_id = rs.tool_id
             LEFT JOIN wmcbid ON wmcbid.gtin = rs.base_upc
             LEFT JOIN bid ON bid.tool_id::text = wmcbid.item_id
             LEFT JOIN bn ON bn.brand_name = rs.brand_name
             LEFT JOIN sl ON sl.prime_item_num = ssa.prime_item_nbr
             LEFT JOIN c c_1 ON c_1.category_name = cbm_1.cat
        ) t1
     LEFT JOIN wm_catalog2 w ON t1.item_id = w.item_num
     LEFT JOIN cat_by_model cbm ON cbm.model = t1.model
     LEFT JOIN category c ON c.category_name = cbm.cat
     LEFT JOIN lookups.item_status_store stat ON t1.model = stat.model

)
;

