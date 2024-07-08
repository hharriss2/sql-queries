--copied format of sub cat sales and applied it to models

create or replace view forecast.model_sales as (
with model_months as 
	(
	select model
	,date_part('month', mod_date) as month_num
	,date_part('year', mod_date) as year_num
	from lookups.model_date
--	where sub_cat in( 'Aquatic and reptile equipment and decor','Folding Beds')
	)
,model_totals as
	(
	select model
	,date_part('year',date_shipped) as year_num
	,date_part('month',date_shipped) as month_num
	,case -- take only a percent of sales that happen during this year. it'll be summed later 
		--ex. 2020 sales are multiplied by less to lower the sum by month later on
	when date_part('year',date_shipped) = 2019 then (.9 * sum(units))::bigint
	when date_part('year',date_shipped) = 2020 then (.5 * sum(units))::bigint
	when date_part('year',date_shipped) = 2021 then (.7 * sum(units))::bigint
	when date_part('year',date_shipped) = 2022 then (.9 * sum(units))::bigint
	when date_part('year',date_shipped) = 2023 then (.9 * sum(units))::bigint
	when date_part('year',date_shipped) = 2024 then (.9 * sum(units))::bigint
	end as total_units-- needs to be updated as new years come
	from ships_schema.ships
	-- where date_part('year',date_shipped) = 2021
--	where sub_cat in( 'Aquatic and reptile equipment and decor','Folding Beds')
	group by model
	, date_part('month',date_shipped)
	,date_part('year',date_shipped)
	)
select scm.model
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
from model_months scm
left join model_totals sct
on (sct.model = scm.model and sct.month_num = scm.month_num and sct.year_num = scm.year_num)
);
