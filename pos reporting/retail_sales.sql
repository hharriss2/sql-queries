create or replace view pos_reporting.retail_sales as (
with r  as --retail sales
(
 SELECT retail_link_pos.id,
    retail_link_pos.item_id::text AS tool_id,
    retail_link_pos.product_name,
    retail_link_pos.upc,
    retail_link_pos.brand_name,
    retail_link_pos.base_upc,
    retail_link_pos.sale_date,
    retail_link_pos.wm_week + 100 AS wm_week,
    retail_link_pos.units,
    retail_link_pos.sales,
    retail_link_pos.item_type,
    retail_link_pos.is_put
   FROM retail_link_pos
)
,p as --pick up today units
(--these are store sold items that are accounted for in com. doubles up the numbers
select 
	item_id
	,sale_date
	,sum(units) as units
from pos_reporting.put_item_units
group by item_id, sale_date
)

select r.id,
	r.tool_id,
    r.product_name,
    r.upc,
    r.brand_name,
    r.base_upc,
    r.sale_date,
    r.wm_week,
    (r.units - p.units)::integer as units, -- subtract ecomm from store units
    r.sales,
    r.item_type,
    r.is_put
from r 
left join p 
on r.tool_id::bigint = p.item_id and r.sale_date = p.sale_date and r.item_type = 'DSV'
--p is only dsv items
)