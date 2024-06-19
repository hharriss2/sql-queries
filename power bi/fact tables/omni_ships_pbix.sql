   create or replace view power_bi.omni_ships_pbix as 
(
with s as --ships
( -- combining ships wiht master tool id model list to find most recent tool id 
	--better helps connect group ids
select
	t1.id
	,t1.model
	,coalesce(t2.item_id::text, t1.tool_id) as tool_id
	,t1.retailer
	,t1.sale_type
	,t1.date_shipped
	,t1.sales
	,t1.units
	,t1.division
	,t1.product_name
from ships_schema.ships t1
left join clean_data.master_com_list t2
on t1.model = t2.model
)
 SELECT DISTINCT s.id,
    m.model_id,
    p.product_name_id,
    t.tool_id_id::integer AS tool_id_id,
        CASE
            WHEN d.division_id = 7 THEN 6 -- change dorel asia to dorel living
            ELSE d.division_id
        END AS division_id,
    r.retailer_id,
    c.category_id,
    s.units,
    s.sales,
    st.sale_type_id::integer AS sale_type_id,
    s.date_shipped,
    g.group_id,
    a.account_manager_id,
    cbm.cbm_id,
    g.group_id_id
   	FROM s
     LEFT JOIN cat_by_model cbm ON s.model::text = cbm.model
     JOIN divisions d ON s.division::text = d.division_name
     JOIN retailer r ON s.retailer::text = r.retailer_name
     LEFT JOIN tool_id_view t ON s.tool_id::text = t.tool_id::text
     LEFT JOIN group_ids g ON s.tool_id::text = g.tool_id::text
     LEFT JOIN category c ON cbm.cat = c.category_name
     JOIN power_bi.sale_type_view st ON st.sale_type::text = s.sale_type::text
     LEFT JOIN power_bi.model_view_pbix m ON m.model_name::text = s.model::text
     LEFT JOIN power_bi.product_name_pbix p ON p.model = s.model::text
     LEFT JOIN power_bi.account_manager_view a ON a.account_manager_id = c.am_id
     )
     ;
     
