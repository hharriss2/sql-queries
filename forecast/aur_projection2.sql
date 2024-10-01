--not sure if first aur projection is obsolete or not
--this query is currently what is running in data base
--item sale date looks recently built so we'll see
create or replace view forecast.aur_projection as (
WITH retail_price AS 
(
SELECT rp.item_id
		,rp.price_retail AS current_price
		,edr.retail_price AS edr_price
		,edr.sale_year
FROM ( 
	SELECT retail_price_1.item_id
           ,retail_price_1.price_retail
           ,date_part('month'::text, now()::date) AS current_month
	FROM power_bi.retail_price retail_price_1
	) rp
	JOIN forecast.edr_year edr 
	ON rp.item_id = edr.item_id
	WHERE 1 = 1 
	AND edr.sale_year = date_part('year'::text, now())
)
,aur_change AS 
(
SELECT aur_trends.item_id
	,aur_trends.sale_month
	,avg(aur_trends.aur_trend)::numeric(10,2) AS aur_trend
FROM ( 
	SELECT month_aur.item_id
    ,aur_id
    ,month_year
    ,month_aur.sale_year
    ,month_aur.sale_month
    ,((aur_month - edr.retail_price) / edr.retail_price)::numeric(10,2) AS aur_trend
	FROM ( 
		SELECT dense_rank() 
		OVER (PARTITION BY isd.item_id ORDER BY (to_char(isd.sale_date::timestamp with time zone, 'YYYY-MM'::text)) DESC) 
		AS aur_id
        ,isd.item_id
        ,to_char(isd.sale_date::timestamp with time zone, 'YYYY-MM'::text) AS month_year
        ,date_part('year'::text, isd.sale_date) AS sale_year
        ,date_part('month'::text, isd.sale_date) AS sale_month
        ,sum(r.sales) / sum(r.units)::numeric AS aur_month
        ,dense_rank() 
        OVER (PARTITION BY isd.item_id ORDER BY (to_char(isd.sale_date::timestamp with time zone,'YYYY-MM'::text))) 
        AS first_month
        FROM ( 
        	SELECT retail_link_pos.item_id
                ,to_char(retail_link_pos.sale_date::timestamp with time zone, 'YYYY-MM'::text) AS month_year
                ,date_part('year'::text, retail_link_pos.sale_date) AS sale_year
                ,date_part('month'::text, retail_link_pos.sale_date) AS sale_month
                ,retail_link_pos.sales
                ,retail_link_pos.units
			FROM retail_link_pos
			WHERE retail_link_pos.units > 0 
			AND retail_link_pos.sales > 0::numeric
			) r
        RIGHT JOIN lookups.item_id_sale_dates isd 
        ON r.item_id = isd.item_id 
        AND r.sale_year = date_part('year'::text, isd.sale_date) 
        AND r.sale_month = date_part('month'::text, isd.sale_date)
		WHERE 1 = 1
		GROUP BY isd.item_id
			,(to_char(isd.sale_date::timestamp with time zone, 'YYYY-MM'::text))
			,(date_part('year'::text, isd.sale_date)), (date_part('month'::text, isd.sale_date))
		) month_aur
     JOIN forecast.edr_year edr 
     ON month_aur.item_id = edr.item_id 
     AND month_aur.sale_year = edr.sale_year
	WHERE 1 = 1 
	AND edr.retail_price > 0::numeric
	) aur_trends
GROUP BY aur_trends.item_id, aur_trends.sale_month
)
SELECT retail_price.item_id
    ,COALESCE(
        CASE
            WHEN date_part('month'::text, now()) = aur_change.sale_month THEN retail_price.current_price
            ELSE (retail_price.edr_price * (1::numeric + aur_change.aur_trend))::numeric(10,2)
        END, retail_price.edr_price) AS projected_aur
      ,aur_change.sale_month
   FROM retail_price
     JOIN aur_change ON retail_price.item_id = aur_change.item_id
);