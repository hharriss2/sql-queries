
create view misc_views.promo_funding_analyze as (
with 
	pfc as (
			select * 
			from power_bi.promo_funding_clean pfc 
			where cat in ('Seating')-- specifically for peytons buyer. switch condition for other items
			and pfc.promo_type = 'Tax Time 2022'
			)
	, rs as
			(
			select * 
			from misc_views.retail_sales
			where units >= 0
			and sales >0--0's are out of stocks or returns
			)
	,l_52 as 
			(
			select tool_id, sum(units::numeric(10,2))/ count(distinct wm_week) as l_52_average
			from misc_views.retail_sales
			where wm_week in 
							(
							 select distinct wm_week
							 from misc_views.retail_sales
							 where wm_week != (select max(wm_week) from misc_views.retail_sales)
							 order by wm_week desc
							 limit 52 
							)--get latest 52 weeks of sales
		   and tool_id::integer in 
		   					(
		   					select distinct tool_id 
		   					from power_bi.promo_funding_clean pfc 
							where cat in ('Seating')-- specifically for peytons buyer. switch condition for other items
							)
			group by tool_id
			)
	,bb as (
			select item_id, available
			from scrape_data.most_recent_scrape --find most recent availability
			
			)
select distinct pfc.tool_id
				, case when bb.available = 'TRUE' then 'Available'
					else 'Unavailable' end as "Is Available?"
				, pfc.cat as "Category"
				, pfc.product_name as "Product Name"
				, sum(rs.units) as "Unit Sales During Promo"
				, pfc.funding_amt as "Funding Amount"
				, sum(rs.units) * pfc.funding_amt as "Projected Co op Spending"
				,avg(rs.units)::numeric(10,2) as "Avg Units During Promo per Week Sold"
				,l_52_average::numeric(10,2) as "Avg units during last 52 per Week Sold"
from pfc 
join rs on pfc.tool_id = rs.tool_id::integer
join l_52 on rs.tool_id = l_52.tool_id
join bb on l_52.tool_id = bb.item_id::text
where pfc.start_date <= rs.wm_week
and pfc.end_date >= rs.wm_week
group by pfc.tool_id
		,bb.available 
		,pfc.cat
		,pfc.product_name
		,pfc.funding_amt
		,l_52_average);