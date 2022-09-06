--assigns every month and year to every sub cat. 

create or replace view forecast.sub_cat_sales as (

with sub_cat_months as 
	(
	select sub_cat
	,date_part('month', sc_date) as month_num
	,date_part('year', sc_date) as year_num
	from lookups.sub_cat_lookup
--	where sub_cat in( 'Aquatic and reptile equipment and decor','Folding Beds')
	)
,sub_cat_totals as
	(
	select sub_cat
	,date_part('year',sale_date) as year_num
	,date_part('month',sale_date) as month_num
	,case -- take only a percent of sales that happen during this year. it'll be summed later 
		--ex. 2020 sales are multiplied by less to lower the sum by month later on
	when date_part('year',sale_date) = 2019 then (.9 * sum(units))::integer
	when date_part('year',sale_date) = 2020 then (.5 * sum(units))::integer
	when date_part('year',sale_date) = 2021 then (.7 * sum(units))::integer
	when date_part('year',sale_date) = 2022 then (.9 * sum(units))::integer
	end as total_units-- needs to be updated as new years come
	from test_com tc
	join cat_by_model cbm
	on tc.model = cbm.model
--	where sub_cat in( 'Aquatic and reptile equipment and decor','Folding Beds')
	group by sub_cat
	, date_part('month',sale_date)
	,date_part('year',sale_date)
	)
select scm.sub_cat
	,coalesce(scm.month_num, sct.month_num) as month_num
	,coalesce(scm.year_num, sct.year_num) as year_num
--	,case when sct.month_key = 1 then total_units
--		when sc
	--any negatives for the month change to 0, null keep as null
	--0 = negative becasue we want to account for that sub cat being active when averaging
	,case 
	when total_units >=0 then total_units
	when total_units <=0 then 0 
	when total_units::integer is null then null
	end as total_units
from sub_cat_months scm
left join sub_cat_totals sct
on (sct.sub_cat = scm.sub_cat and sct.month_num = scm.month_num and sct.year_num = scm.year_num)
)
;