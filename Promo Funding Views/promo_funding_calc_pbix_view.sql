 



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