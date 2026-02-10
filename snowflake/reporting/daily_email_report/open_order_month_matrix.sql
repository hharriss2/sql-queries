/*for the daily report. day runs down first column, month sales run down the others columns
example:
    day     jan     feb     march       etc
    1       50      100     25
    2       0       50      25
    3       50      50      50
    ...
    total   100     200     100         ...
 */
create or replace view walmart.reporting.open_order_month_matrix as 
(
with order_matrix as
( 
--open orders running down by day. columns are by month 
select
    date_part('day',transaction_date) as order_id -- to get the ordering for 1-33. 32 will be total, 33 will be average
    ,date_part('day',transaction_date) as requested_day
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-01-01'
        then gross_sales
        else 0
        end
        ) as january_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-02-01'
        then gross_sales
        else 0
        end
        ) as february_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-03-01'
        then gross_sales
        else 0
        end
        ) as march_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-04-01'
        then gross_sales
        else 0
        end
        ) as april_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-05-01'
        then gross_sales
        else 0
        end
        ) as may_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-06-01'
        then gross_sales
        else 0
        end
        ) as june_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-07-01'
        then gross_sales
        else 0
        end
        ) as july_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-08-01'
        then gross_sales
        else 0
        end
        ) as august_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-09-01'
        then gross_sales
        else 0
        end
        ) as september_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-10-01'
        then gross_sales
        else 0
        end
        ) as october_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-11-01'
        then gross_sales
        else 0
        end
        ) as november_sales
    ,sum(
        case
        when date_trunc('month',transaction_date) = '2026-12-01'
        then gross_sales
        else 0
        end
        ) as december_sales
from walmart.core.customer_orders
group by requested_day
order by requested_day
)
,matrix_append as 
(
select 
    order_id
    ,requested_day::text as requested_day
    ,january_sales
    ,february_sales
    ,march_sales
    ,april_sales
    ,may_sales
    ,june_sales
    ,july_sales
    ,august_sales
    ,september_sales
    ,october_sales
    ,november_sales
    ,december_sales
from order_matrix
union all
SELECT
    32 as order_id
    ,'Total' AS requested_day
    ,SUM(january_sales)  AS january_sales
    ,SUM(february_sales) AS february_sales
    ,SUM(march_sales)    AS march_sales
    ,sum(april_sales) as april_sales
    ,sum(may_sales) as may_sales
    ,sum(june_sales) as june_sales
    ,sum(july_sales) as july_sales
    ,sum(august_sales) as august_sales
    ,sum(september_sales) as september_sales
    ,sum(october_sales) as october_sales
    ,sum(november_sales) as november_sales
    ,sum(december_sales) as december_sales
FROM order_matrix
)
select 
    order_id
    ,requested_day
    ,january_sales
    ,february_sales
    ,march_sales
    ,april_sales
    ,may_sales
    ,june_sales
    ,july_sales
    ,august_sales
    ,september_sales
    ,october_sales
    ,november_sales
    ,december_sales
from matrix_append
order by order_id
)