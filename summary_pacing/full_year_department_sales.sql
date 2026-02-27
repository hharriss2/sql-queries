--used to power the generated excel file for summary pacing report.
create or replace view summary_pacing.full_year_department_sales as 
(
with bc as  -- budget category
(
select
	department
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
from summary_pacing.budget_tbl bt
left join dim_sources.dim_cat_by_model cbm
on bt.model = cbm.model
group by cbm.department
order by total_budget desc
)
,sbc as --ships by department
(
select department
,sum(case 
	when date_part('year',month_shipped) = 2026
	then total_sales else 0
	end) as actual_sales
,sum(
	case
	when date_part('year',month_shipped) = date_part('year', current_date - interval '1 year')
	then total_sales else 0
	end) as prior_sales 
from summary_pacing.ship_by_department sbc
where date_part('year',month_shipped) >= 2025
group by department
)
,uni as --combining the budget and ships sales data
(
select bc.department
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
on bc.department = sbc.department
)
,details as 
(
select department
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
    'Total' as department
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
select department
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
