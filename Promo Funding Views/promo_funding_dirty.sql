/*start promo dirty view*/

SELECT DISTINCT pf.id,
    cbm.cat,
    coalesce(s.model, pf.model) as model,
    pr.product_name,
    pf.tool_id,
    pf.start_date,
    pf.end_date,
    pf.funding_amt,
    pf.promo_type,
    pf.suggested_retail
   FROM promo_funding_staging pf
   LEFT JOIN ( 
   		select * 
   		from clean_data.master_com_list
         		) s 
     ON pf.tool_id = s.item_id::text
     LEFT JOIN cat_by_model cbm ON cbm.model =
        CASE
            WHEN s.model::text IS NULL THEN pf.model::character varying
            ELSE s.model
        END::text
     LEFT JOIN products_raw pr ON pr.model =
        CASE
            WHEN s.model::text IS NULL THEN pf.model::character varying
            ELSE s.model
        END::text
  WHERE 1 = 1 AND NOT (cbm.cat IN ( SELECT DISTINCT cat_by_model.cat
           FROM cat_by_model)) OR NOT (s.model::text IN ( SELECT model_view.model_name
           FROM model_view)) AND NOT (pf.model IN ( SELECT DISTINCT model_view.model_name
           FROM model_view)) OR NOT (pr.product_name IN ( SELECT product_name_view.product_name
           FROM product_name_view)) OR NOT (pf.tool_id IN ( SELECT DISTINCT tool_id_view.tool_id
           FROM tool_id_view)) OR pf.start_date = '#N/A'::text OR s.model::text = '#N/A'::text OR pf.tool_id = '#N/A'::text OR cbm.cat = '#N/A'::text OR pf.tool_id = ''::text
/*end promo dirty view */