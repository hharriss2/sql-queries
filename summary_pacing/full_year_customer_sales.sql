--used to get the full year table for category by budget and sales 
create or replace view summary_pacing.full_year_customer_sales as 
(
with bc as --budget customer
( -- breaking down the budget by customer
select
	hf_retailer_group
	,sum(budget_sales) as total_budget
    ,sum(case
            when sourcing_type = 'Import'
            then budget_sales
            else 0
            end) as di_sales
        ,sum(case
            when sourcing_type = 'Domestic'
            then budget_sales
            else 0
            end) as domestic_sales
        ,sum(case
            when sourcing_type = 'Domestic'
            and date_part('quarter',budget_date) = 1
            then budget_sales
            else 0
            end) as q1_dom_sales
        ,sum(case
            when sourcing_type = 'Domestic'
            and date_part('quarter',budget_date) = 2
            then budget_sales
            else 0
            end) as q2_dom_sales
        ,sum(case
            when sourcing_type = 'Domestic'
            and date_part('quarter',budget_date) = 3
            then budget_sales
            else 0
            end) as q3_dom_sales		
        ,sum(case
            when sourcing_type = 'Domestic'
            and date_part('quarter',budget_date) = 4
            then budget_sales
            else 0
            end) as q4_dom_sales
from summary_pacing.budget_tbl
group by hf_retailer_group
order by total_budget desc
)
,sbc as --ships by customer
(
--matching the budget with actual sales
select rl.hf_retailer_group
,sum(case 
	when date_part('year',month_shipped) = 2026
	then total_sales else 0
	end) as actual_sales
,sum(
	case
	when date_part('year',month_shipped) = date_part('year', current_date - interval '1 year')
	then total_sales else 0
	end) as prior_sales 
from summary_pacing.ship_by_customer sbc
left join components.retail_list rl
on sbc.hf_customer_number = rl.hf_customer_number
where date_part('year',month_shipped) >= 2025
group by rl.hf_retailer_group
)
,uni as 
( -- joining the budget and actual sales to bring over sales info
select
	bc.hf_retailer_group
	,total_budget
	,sbc.actual_sales
	,sbc.prior_sales
    ,di_sales
    ,domestic_sales
    ,q1_dom_sales
    ,q2_dom_sales
    ,q3_dom_sales		
    ,q4_dom_sales
    ,1 as row_id
from bc
join sbc
on bc.hf_retailer_group = sbc.hf_retailer_group
)
,details as 
( -- unioning the results with the 'total' to create a total row
select hf_retailer_group
    ,total_budget
    ,actual_sales
    ,prior_sales
    ,di_sales
    ,domestic_sales
    ,q1_dom_sales
    ,q2_dom_sales
    ,q3_dom_sales		
    ,q4_dom_sales
    ,row_id
from uni
union all 
select 
    'Total' as hf_retailer_group
    ,sum(total_budget) as total_budget
    ,sum(actual_sales) as actual_sales
    ,sum(prior_sales) as prior_sales
    ,sum(di_sales) as di_sales
    ,sum(domestic_sales) as domestic_sales
    ,sum(q1_dom_sales) as q1_dom_sales
    ,sum(q2_dom_sales) as q2_dom_sales
    ,sum(q3_dom_sales) as q3_dom_sales
    ,sum(q4_dom_sales) as q4_dom_sales
    ,2 as row_id
from uni
)

select hf_retailer_group
,total_budget
,actual_sales
,prior_sales
--last metrics are used for the table on the right
,di_sales
,di_sales / max(di_sales) over () as di_percent_total
,domestic_sales
,domestic_sales / max(domestic_sales) over () as domestic_percent_total
,q1_dom_sales
,q2_dom_sales
,q3_dom_sales		
,q4_dom_sales
from details
order by row_id
)
;

