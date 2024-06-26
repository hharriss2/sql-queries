--finds most recent brand name asscociated with a tool/item id
create or replace view lookups.tool_brand as 
(
with tb as 
(
SELECT 
 tool_id
  ,brand_name
  ,sale_date
FROM pos_reporting.retail_sales
WHERE brand_name IS NOT NULL
)
,tbmax as 
(
select 
	tool_id
	,max(sale_date) as date_compare
from tb
group by tool_id
)
select DISTINCT 
	tb.tool_id
	,tb.brand_name
from tb
join tbmax
on tb.tool_id = tbmax.tool_id 
and tb.sale_date =tbmax.date_compare
)
;
