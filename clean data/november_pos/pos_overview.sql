--quick ask from kevin that looks at november sales comparisons

--quick ask from kevin that looks at november sales comparisons

create or replace view pos_reporting.pos_november_overview as 
(
select
	model
	,tool_id::bigint as item_id
	,cbm_id
	,case
		when date_part('year',sale_date) = 2024
		then cast (sale_date - interval '1 day' as date)
		else sale_date end as sale_date
	,units
	,sales
	,item_type
	,'WM Ecomm' as retailer_name
    ,product_name
from pos_reporting.wm_com_pos
where 1=1
and sale_date between '2024-11-23' and '2024-12-01'
or sale_date between '2025-11-22' and '2025-11-30'
union all
select 
	model
	,item_id::bigint as item_id
	,cbm_id
	,case
		when date_part('year',sale_date) = 2024
		then cast(sale_date - interval '1 day' as date)
		else sale_date end as sale_date
	,pos_qty as units
	,pos_sales as sales
	,'Stores' as item_type
	,'WM Stores' as retailer_name
    ,product_name
from pos_reporting.wm_stores_pos
where 1=1
and sale_date between '2024-11-23' and '2024-12-01'
or sale_date between '2025-11-22' and '2025-11-30'
union all 
select
	asin as model
	,null::bigint as item_id
	,null as cbm_id
	,case
		when date_part('year',sale_date) = 2024
		then cast (sale_date - interval '1 day' as date)
		else sale_date end as sale_date
	,shipped_units as units
	,shipped_revenue as sales
	,'1P' as item_type
	,'Amazon' as retailer_name
	,product_title as product_name
from pos_reporting.amazon_1p
where 1=1
and sale_date between '2024-11-23' and '2024-12-01'
or sale_date between '2025-11-22' and '2025-11-30'
union all

select
	sku as model
	,null as item_id
	,cbm.cbm_id
	,case
		when date_part('year',date_time::date) = 2024 
		then cast (date_time::date - interval '1 day' as date)
		else date_time::date end as sale_date
	,quantity as units
	,product_sales as sales
	,'3P' as item_type
	,'Amazon' as retailer_name
	,description as product_name
from pos_reporting.amazon_3p a3p
left join cat_by_model cbm
on a3p.sku = cbm.model
where 1=1
and type = 'Order'

and( date_time::date between '2024-11-23' and '2024-12-01'
or date_time::date between '2025-11-22' and '2025-11-30'
)
union all

select t3.partner_sku as model
	,t3.tcin::bigint as item_id
	,cbm_id
	,case
		when date_part('year',date_placed::date) = 2024
		then cast (date_placed::date - interval '1 day' as date)
		else date_placed::date end as sale_date
	,quantity as units
	,unit_price as sales
	,'3P' as item_type
	,'Target' as retailer_name
	,tc.product_name
from pos_reporting.target_3p t3
left join components.target_catalog tc
on t3.tcin = tc.tcin
left join cat_by_model cbm
on t3.partner_sku = cbm.model
where 1=1
and date_placed::date between '2024-11-23' and '2024-12-01'
or date_placed::date between '2025-11-22' and '2025-11-30'
union all

select 
	coalesce(tc.partner_sku, t3.manufacturer_style) as model
	,t3.tcin::bigint as item_id
	,cbm_id
	,case
		when date_part('year',sales_date) = 2024
		then cast (sales_date - interval '1 day' as date)
		else sales_date end as sale_date
	,sale_quantity as units
	,sale_amount as sales
	,'1P' as item_type
	,'Target' as retailer_name
	,item_description as product_name
from pos_reporting.target_pos_sales t3 
left join components.target_catalog tc
on t3.tcin = tc.tcin
left join cat_by_model cbm
on tc.partner_sku = cbm.model
where 1=1
and sales_date between '2024-11-23' and '2024-12-01'
or sales_date between '2025-11-22' and '2025-11-30'
)
;
create or replace view pos_reporting.pos_november_top_10 as 
(
with sales_by_item as  -- find the sales for each item in 2025 and 2024
(
select 
	model
	,item_id
	,cbm_id
	,sum(case
		when sale_date>='2025-11-23'
		then sales
		else 0
		end
		) total_sales_2025
	,sum(case
		when sale_date>='2024-11-23'
        and sale_date <= current_date - interval '1 year 1 day'
		then sales
		else 0
		end
		) total_sales_2024
	,sum(case
		when sale_date>='2025-11-23'
		then units
		else 0
		end
		) total_units_2025
	,sum(case
		when sale_date>='2024-11-23'
        and sale_date <= current_date - interval '1 year 1 day'
		then units
		else null
		end
		) total_units_2024
	,retailer_name
    ,product_name
from pos_reporting.pos_november_overview
--where retailer_name = 'WM Ecomm'
group by model
	,item_id
	,cbm_id
	,retailer_name
    ,product_name
order by total_units_2025 desc
)
,details as 
(
select * 
	,dense_rank() over (partition by retailer_name order by total_units_2025 desc) as item_ranking
from sales_by_item
)
select * 
from details
where item_ranking <=10
order by retailer_name, item_ranking
)