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
				     RIGHT JOIN pos_reporting.promo_funding_clean pf ON s.tool_id::integer = pf.tool_id
				  WHERE s.wm_week >= pf.start_date AND s.wm_week <= pf.end_date AND pf.funding_amt > 0::numeric
				  --show only sales between week 1 and 13
--				  and s.wm_week >=202301 
--				  and s.wm_week <=202313
