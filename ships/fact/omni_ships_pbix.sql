create or replace view power_bi.omni_ships_pbix as 
(
with s as 
(
select * 
from ships_schema.ships_view
)

SELECT 
	s.id
	,m.model_id::bigint as model_id
	,p.product_name_id::bigint as product_name_id
	,t.item_id_id::integer AS tool_id_id
	,s.division_id
	,case -- some reason this model is showing up as sams stores instead of .com 
		when s.model = '60835GRTW4ES'
		then 3 else s.retailer_id
		end as retailer_id
	,s.category_id
	,s.units
	,s.sales
	,s.sale_type_id
	,s.date_shipped
	,s.group_id
	,s.account_manager_id
	,s.cbm_id
	,s.group_id_id
FROM s
LEFT JOIN power_bi.dim_ships_item_id t 
ON s.tool_id = t.item_id::text
LEFT JOIN power_bi.dim_models m 
ON m.model_name = s.model
LEFT JOIN power_bi.dim_product_names p 
ON p.product_name = s.product_name
)
;
