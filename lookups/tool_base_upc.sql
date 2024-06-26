create or replace view lookups.tool_base_upc as 
(
with tb as 
(
select 
	tool_id
	,base_upc
	,sale_date
	from pos_reporting.retail_sales
	where base_upc is not null
)
,tbmax as --tool base max
(
select 
	tool_id
	,max(sale_date) as date_compare
from tb
group by tool_id
)
select distinct
	tb.tool_id
	,tb.base_upc
from tb
join tbmax
on tb.tool_id = tbmax.tool_id
and tb.sale_date = tbmax.date_compare
)
;
