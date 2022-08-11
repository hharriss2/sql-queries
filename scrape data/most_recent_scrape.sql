/*Finds the most recent scrape of wm products for the buy box*/

create or replace view scrape_data.most_recent_scrape as (	
 SELECT DISTINCT sh.id,
    sh.url,
    sh.item_id,
    sh.product_name,
    sh.manufacturer_name,
    sh.available,
    sh.num_of_images,
    coalesce(lt.model_name::text,sh.model_name::text) as model_name,
    sh.category_path,
    sh.category_path_name,
    sh.upc,
    sh.num_of_variants,
    sh.price_retail,
    sh.price_was,
    sh.price_display_code,
    sh.review_rating,
    sh.review_count,
    sh.free_shipping,
    sh.two_day_shipping,
    sh.shelf_position,
    sh.est_days_shipped,
    sh.enabled_freight_shipping,
    sh.seller_name,
    coalesce(cbid.base_id::text, sh.base_id::text) as base_id,
    sh.description,
    sh.inserted_at,
    g.group_id,
    ic.class,
    lt.division,
    lt.cat,
    pc.early_date,
    pc.recent_date,
    pc.early_retail,
    pc.recent_retail,
    pc.recent_over_early_retail
FROM scrape_data.scrape_tbl sh
left join group_ids g
on sh.item_id = g.tool_id
LEFT JOIN lookups.current_base_id cbid
on g.group_id = cbid.group_id
left join item_class ic 
on ic.tool_id::integer = sh.item_id
left join
	(select distinct model_name, division, cat, item_id
	 from lookups.lookup_tbl
	 ) lt
on lt.item_id = sh.item_id
left join scrape_data.price_compare pc 
on sh.item_id = pc.item_id
WHERE sh.date_inserted = (( 
			SELECT max(sh_1.date_inserted) AS max
           	FROM scrape_data.scrape_tbl sh_1
           	)) 
AND (
	sh.item_id IN 
		( 
		SELECT item_id
       	FROM lookups.tool_id_numeric
       	)
    )
)
;

