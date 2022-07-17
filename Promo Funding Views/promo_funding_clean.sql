/*OLD VIEW */
/*promo funding clean view*/
SELECT DISTINCT 
 	pf.id, 
    cbm.cat,
    coalesce(s.model, pf.model) as model,
    pr.product_name,
    pf.tool_id::integer AS tool_id,
    pf.start_date::integer + 100 AS start_date,
    pf.end_date::integer + 100 AS end_date,
        CASE --if sales team enters in a $ sign, it gets rid of the symbold and turns the value to a number
            WHEN pf.funding_amt ~~ '%$%'::text THEN substr(pf.funding_amt, 2)::numeric(10,2)
            ELSE pf.funding_amt::numeric(10,2)--otherwise convert the amount to a numer
        END AS funding_amt,
    pf.promo_type,
        CASE--you must put in a suggested retail for the item
            WHEN pf.suggested_retail = ''::text THEN NULL::numeric
            WHEN pf.suggested_retail ~~ '%$%'::text THEN substr(pf.suggested_retail, 2)::numeric(10,2)
            ELSE pf.suggested_retail::numeric(10,2)
        END AS suggested_retail,
    w.wm_date::integer AS submit_date
FROM promo_funding_staging pf
JOIN ( --finds the most recent promo submitted
	SELECT DISTINCT pf.tool_id,
    pf.promo_type,
    pf.start_date,
    pf.end_date,
    max(pf.inserted_at) AS date_compare
    FROM promo_funding_staging pf
    GROUP BY pf.tool_id
    		, pf.promo_type
    		, pf.start_date
    		, pf.end_date
    ) ps2 
ON pf.tool_id = ps2.tool_id AND pf.promo_type = ps2.promo_type AND pf.inserted_at = ps2.date_compare
     LEFT JOIN ( 
     			select * 
     			from clean_data.master_com_list
				
				) s ON pf.tool_id = s.item_id::text
     LEFT JOIN cat_by_model cbm ON cbm.model = coalesce(s.model,pf.model)
     LEFT JOIN products_raw pr ON pr.model = s.model::text
     LEFT JOIN wm_calendar w ON w.date = pf.inserted_at::date
  WHERE 1 = 1 AND NOT (pf.id IN ( SELECT DISTINCT promo_funding_dirty.id
           FROM misc_views.promo_funding_dirty));
/*end promo clean view*/  

/*NEWEST VIEW*/
/*promo funding clean view*/
create  or replace view pos_reporting.promo_funding_clean_view as (
SELECT DISTINCT 
 	pf.id, 
    cbm.cat,
    coalesce(sl.model,s.model, pf.model) as model,
    pr.product_name,
    pf.tool_id::integer AS tool_id,
    pf.start_date,
    pf.end_date,
        CASE --if sales team enters in a $ sign, it gets rid of the symbold and turns the value to a number
            WHEN pf.funding_amt ~~ '%$%'::text THEN substr(pf.funding_amt, 2)::numeric(10,2)
            ELSE pf.funding_amt::numeric(10,2)--otherwise convert the amount to a numer
        END AS funding_amt,
    pf.promo_type,
        CASE--you must put in a suggested retail for the item
            WHEN pf.suggested_retail = ''::text THEN NULL::numeric
            WHEN pf.suggested_retail ~~ '%$%'::text THEN substr(pf.suggested_retail, 2)::numeric(10,2)
            ELSE pf.suggested_retail::numeric(10,2)
        END AS suggested_retail,
    pf.inserted_at::date as submit_date,
    coalesce(sl.division, s.division) as division
FROM promo_funding_staging2 pf
JOIN ( --finds the most recent promo submitted
	SELECT DISTINCT pf.tool_id,
    pf.promo_type,
    pf.start_date,
    pf.end_date,
    max(pf.inserted_at) AS date_compare
    FROM promo_funding_staging2 pf
    GROUP BY pf.tool_id
    		, pf.promo_type
    		, pf.start_date
    		, pf.end_date
    ) ps2 
ON pf.tool_id = ps2.tool_id AND pf.promo_type = ps2.promo_type AND pf.inserted_at = ps2.date_compare
     LEFT JOIN ( 
     			select * 
     			from clean_data.master_com_list
				
				) s ON pf.tool_id = s.item_id::text
	left join (
				select * 
				from pos_reporting.lookup_com
				) sl
	on pf.tool_id = sl.item_id
     LEFT JOIN cat_by_model cbm ON cbm.model = coalesce(s.model,pf.model)
     LEFT JOIN products_raw pr ON pr.model = s.model::text
  WHERE 1 = 1 AND NOT (pf.id IN ( SELECT DISTINCT promo_funding_dirty2.id
           FROM misc_views.promo_funding_dirty2))
/*end promo clean view*/  
);