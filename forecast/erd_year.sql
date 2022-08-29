create view forecast.edr_year as ( 
--finds the every day retail
--most popular AUR for by item, by year
select item_id, sale_year, retail_price
from
(
	select item_id -- item id
		,date_part('year',sale_date) as sale_year --year of popular retail
		, (((sales/units) * .1)::numeric(10,0))* 10 as retail_price -- finding aur aka retail prices. rounding up the ranking to the 10's 
		,row_number() over (partition by item_id, date_part('year',sale_date) order by count(date_part('year',sale_date)) desc) count_rank
		--count_rank ranks the most popular retail_price for the years 
		,count(date_part('year', sale_date)) as num_times_at_retail
		--just a check. see how many times the retail sold during that yera
	
	from retail_link_pos 
	where 1=1
	and units >0
	group by item_id
		,date_part('year',sale_date) 
		,(((sales/units) * .1)::numeric(10,0))* 10
) retail_ranking
where count_rank = 1
)
;