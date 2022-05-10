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

/*promo_funding_calc_pbix_view*/

with retail_funding as 
	(
	SELECT DISTINCT pf.id,
            s.id AS sid,
            pf.model,
            s.wm_week,
            pf.tool_id,
            s.units,
            pf.funding_amt,
            pf.promo_type,
            pf.start_date,
            pf.end_date,
            pf.submit_date AS submit_week,
            pf.suggested_retail,
            pf.product_name,
            (s.units::numeric * pf.funding_amt)::numeric(10,2) AS sales_funding,
            s.sales::real AS sales
     FROM pos_reporting.retail_sales s
  	 RIGHT  join pos_reporting.promo_funding_clean pf ON s.tool_id::integer = pf.tool_id
     WHERE s.wm_week >= pf.start_date AND s.wm_week <= pf.end_date AND pf.funding_amt > 0::numeric
	)
,cbm as 
	(
	select *
	from cat_by_model
	)
,c as (select *
		from power_bi.category_view
		)
,m as 
	(
	select * 
	from power_bi.model_view_pbix
	)
,t as 
	(
	select * 
	from power_bi.tool_id_view
	)
,a as 
	(
	select * 
	from power_bi.account_manager_view
	)
,pr as 
	(
	select distinct model, division, product_name
	from products_raw
	)
,d as 
	(
	select * 
	from power_bi.divisions_view
	)
,pt as 
	(
	select * 
	from power_bi.promo_type
	)
,wmw1 as 
	(
	select * 
	from wm_calendar_to_months
	)
,wmw2 as 
	(
	select * 
	from wm_calendar_to_months
	)
,wmw3 as 
	(
	select * 
	from wm_calendar_to_months
	)
,pn as
	(
	select * 
	from power_bi.product_name_view_pbix
	)
,g as 
	(
	select * 
	from power_bi.group_id_view
	)
,rp as 
	(
	select * 
	from power_bi.retail_price
	)
select 
	retail_funding.id
	,m.model_id
	,d.division_id
	,cbm.cbm_id
	,t.tool_id_id
	,a.account_manager_id
	,sum(retail_funding.units)::integer as units
	,retail_funding.funding_amt
	,pt.promo_id
	,wmw1.wm_weeks_id as start_week_id
	,wmw2.wm_weeks_id as end_week_id
	,wmw3.wm_weeks_id as submit_week_id
	,retail_funding.suggested_retail
	,pn.product_name_id
	,rp.retail_price_id
	,g.group_id_id
	,sum(retail_funding.sales::numeric(10,2)) AS sales
	,sum(retail_funding.sales_funding)::numeric(10,2) AS funding_amt_total
FROM retail_funding
 join cbm on retail_funding.model = cbm.model
 join c on cbm.cat= c.category_name 
 join m on retail_funding.model = m.model_name
 join t on retail_funding.tool_id::text = t.tool_id 
 join a on a.account_manager_id = c.am_id
 join pr on retail_funding.model = pr.model 
left join divisions d on pr.division = d.division_name
left join pt on retail_funding.promo_type = pt.promo_name
left join wmw1 on retail_funding.start_date = wmw1.wm_date
left join wmw2 on retail_funding.end_date = wmw2.wm_date
left join wmw3 on retail_funding.submit_week = wmw3.wm_date
left join pn on retail_funding.product_name = pn.product_name
left join g on retail_funding.tool_id = g.tool_id
left join rp on retail_funding.tool_id = rp.item_id 
  GROUP BY retail_funding.id
  , m.model_id
  , d.division_id
  , cbm.cbm_id
  , t.tool_id_id
  , a.account_manager_id
  , g.group_id_id
  , retail_funding.funding_amt
  , pt.promo_id
  , wmw1.wm_weeks_id
  , wmw2.wm_weeks_id
  , pn.product_name_id
  , retail_funding.suggested_retail
  , wmw3.wm_weeks_id
  , rp.retail_price_id
;