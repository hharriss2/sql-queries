--top row of the excel sheet 
create or replace view summary_pacing.ships_budget_top_table as 
(
with sa as --ships actual
(
select
	1 as row_id
	,case
		when date_part('year',month_shipped) = 2025
		then '2025 Actual'
		when date_part('year',month_shipped) = 2026
		then '2026 Actual'
		end as date_row
	,case
		when date_part('month',month_shipped) = 1
		then sales
		else 0
		end as jan_sales
	,case
		when date_part('month',month_shipped) = 2
		then sales
		else 0
		end as feb_sales
	,case
		when date_part('month',month_shipped) = 3
		then sales
		else 0
		end as march_sales
	,case
		when date_part('month',month_shipped) = 4
		then sales
		else 0
		end as april_sales
	,case
		when date_part('month',month_shipped) = 5
		then sales
		else 0
		end as may_sales
	,case
		when date_part('month',month_shipped) = 6
		then sales
		else 0
		end as june_sales
	,case
		when date_part('month',month_shipped) = 7
		then sales
		else 0
		end as july_sales
	,case
		when date_part('month',month_shipped) = 8
		then sales
		else 0
		end as august_sales
	,case
		when date_part('month',month_shipped) = 9
		then sales
		else 0
		end as septembet_sales
	,case
		when date_part('month',month_shipped) = 10
		then sales
		else 0
		end as october_sales
	,case
		when date_part('month',month_shipped) = 11
		then sales
		else 0
		end as november_sales
	,case
		when date_part('month',month_shipped) = 12
		then sales
		else 0
		end as december_sales
from summary_pacing.ship_months
where date_part('year',month_shipped) >= 2025
)
,br as --budget row
(
select
	2 as row_id
	,case
		when date_part('year',budget_date) = 2026
		then '2026 Budget'
		else null end as date_row
	,case
		when date_part('month',budget_date) = 1
		then budget_sales
		else 0
		end as jan_sales
	,case
		when date_part('month',budget_date) = 2
		then budget_sales
		else 0
		end as feb_sales
	,case
		when date_part('month',budget_date) = 3
		then budget_sales
		else 0
		end as march_sales
	,case
		when date_part('month',budget_date) = 4
		then budget_sales
		else 0
		end as april_sales
	,case
		when date_part('month',budget_date) = 5
		then budget_sales
		else 0
		end as may_sales
	,case
		when date_part('month',budget_date) = 6
		then budget_sales
		else 0
		end as june_sales
	,case
		when date_part('month',budget_date) = 7
		then budget_sales
		else 0
		end as july_sales
	,case
		when date_part('month',budget_date) = 8
		then budget_sales
		else 0
		end as august_sales
	,case
		when date_part('month',budget_date) = 9
		then budget_sales
		else 0
		end as septembet_sales
	,case
		when date_part('month',budget_date) = 10
		then budget_sales
		else 0
		end as october_sales
	,case
		when date_part('month',budget_date) = 11
		then budget_sales
		else 0
		end as november_sales
	,case
		when date_part('month',budget_date) = 12
		then budget_sales
		else 0
		end as december_sales
from summary_pacing.budget_tbl
where date_part('year',budget_date) = 2026
)
,ru as --rows union
(
select *
from sa
union all 
select * 
from br
)
select row_id
	,date_row
	,sum(jan_sales) as jan_sales
	,sum(feb_sales) as feb_sales
	,sum(march_sales) as march_sales
	,sum(april_sales) as april_sales
	,sum(may_sales) as may_sales
	,sum(june_sales) as june_sales
	,sum(july_sales) as july_sales
	,sum(august_sales) as august_sales
	,sum(septembet_sales) as septembet_sales
	,sum(october_sales) as october_sales
	,sum(november_sales) as november_sales
	,sum(december_sales) as december_sales
	,sum(jan_sales)
		+sum(feb_sales)
		+sum(march_sales)
		+sum(april_sales)
		+sum(may_sales)
        +sum(june_sales)
        +sum(july_sales)
        +sum(august_sales)
        +sum(septembet_sales)
        +sum(october_sales)
        +sum(november_sales)
        +sum(december_sales)
     as total_sales
from ru
group by row_id, date_row
order by row_id, date_row
)