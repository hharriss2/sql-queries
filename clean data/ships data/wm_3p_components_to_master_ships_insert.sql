--updating the master ships list with the wm 3p components
create or replace view dapl_raw.wm_3p_components_to_master_ships_insert as 
(
select
	w.model
	,coalesce(msl.upc,w.upc) as upc
	,coalesce(msl.item_id, w.item_id) as item_id
	,coalesce(msl.product_name,w.product_name) as product_name
	,w.item_id as item_id_3p
	,now() as updated_on
from components.wm_catalog_3p w
left join clean_data.master_ships_list msl
on w.model = msl.model
where 1=1
)