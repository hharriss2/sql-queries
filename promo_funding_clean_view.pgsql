 SELECT distinct 
 t1.id
 ,cat
 ,model
 ,product_name
 ,t1.tool_id
 ,start_date
 ,end_date
 ,funding_amt
 ,t1.promo_type
 ,suggested_retail
 ,w.wm_date as submit_date
FROM 
    (
    SELECT DISTINCT pf.id
    ,cbm.cat
    ,
        CASE
            WHEN s.model IS NULL THEN pf.model::character varying
            ELSE s.model
        END AS model --accounts for wrong model numbers inserted
    ,pr.product_name
    ,pf.tool_id
    ,pf.start_date
    ,pf.end_date,
        CASE
            WHEN pf.funding_amt ~~ '%$%'::text THEN substr(pf.funding_amt, 2)::numeric(10,2)
            ELSE pf.funding_amt::numeric(10,2)
        END AS funding_amt
    ,pf.promo_type,
        CASE
            WHEN pf.suggested_retail = ''::text THEN NULL::numeric
            WHEN pf.suggested_retail ~~ '%$%'::text THEN substr(pf.suggested_retail, 2)::numeric(10,2)
            ELSE pf.suggested_retail::numeric(10,2)
        END AS suggested_retail -- google sheets inserts blanks, not nulls. this sets value to null
    ,w.wm_date AS submit_date
    FROM promo_funding_staging pf
    JOIN 
        (   SELECT DISTINCT 
            promo_funding_staging.tool_id,
            promo_funding_staging.promo_type,
            promo_funding_staging.start_date,
            promo_funding_staging.end_date,
            max(promo_funding_staging.inserted_at) AS date_compare/* date_compare is used if sales team overwrites any promo columns. 
            it overwrites the most based off promo_type and tool_id. If these two factors are unique, its under a new promo*/          
            FROM promo_funding_staging
            GROUP BY promo_funding_staging.tool_id
            , promo_funding_staging.promo_type
            , promo_funding_staging.start_date
            , promo_funding_staging.end_date
        ) ps2 
    ON pf.tool_id = ps2.tool_id AND pf.promo_type = ps2.promo_type AND pf.inserted_at = ps2.date_compare
    LEFT JOIN 
        ( SELECT DISTINCT 
            s1.model,
            s2.tool_id
           FROM 
                ( 
                   SELECT s1_1.model,
                    s1_1.tool_id,
                    max(s1_1.date_shipped) AS date_compare
                   FROM ships s1_1
                   WHERE (s1_1.tool_id::text IN 
                        ( SELECT DISTINCT 
                            promo_funding_staging.tool_id
                           FROM promo_funding_staging
                        ))     
                  GROUP BY s1_1.model, s1_1.tool_id
                  ) s1--s1 finds the most recent model/tool_id combination. models can change over time
             JOIN ( 
                    SELECT DISTINCT ships.tool_id,
                    max(ships.date_shipped) AS date_compare
                    FROM ships
                    GROUP BY ships.tool_id
                    ) s2 ON s1.date_compare = s2.date_compare AND s1.tool_id::text = s2.tool_id::text
         ) s/*second part of comparing ships dates and model. Formatting may be wonky on this*/ ON pf.tool_id = s.tool_id::text
    LEFT JOIN cat_by_model cbm ON cbm.model =
        CASE
            WHEN s.model::text IS NULL THEN pf.model::character varying
            ELSE s.model/* Case join. If the model is null for ships, use model given by sales team*/
        END::text
    LEFT JOIN products_raw pr ON pr.model = s.model::text
    LEFT JOIN wm_calendar w ON w.date = pf.inserted_at::date
   WHERE 1 = 1 AND NOT (pf.id IN (
                                 SELECT DISTINCT promo_funding_dirty.id
   
                                    FROM misc_views.promo_funding_dirty
                                )
                        )/*opposite where conditionals than misc_views.promo_funding_dirty.
                         Causes 3s extra loading time because of union searched within view*/
         )t1
JOIN 
    (
  	select tool_id, promo_type, min(inserted_at) og_date
  	from promo_funding_staging
  	group by tool_id, promo_type  
  	        
    ) t2-- t2 finds original inserted_at date
ON t1.tool_id = t2.tool_id
AND t1.promo_type = t2.promo_type
JOIN wm_calendar w on w.date = og_date::date --replacing actual date with wm week. 
           ;