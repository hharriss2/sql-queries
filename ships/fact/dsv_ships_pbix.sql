--created the view to make a a version of omni ships report
--this table appends with omni_ships_pbix.sql
create or replace view power_bi.dsv_ships_pbix as 
(
select 
	r.dsv_order_id as id
	,m.model_id
	,p.product_name_id
	,i.item_id_id as tool_id_id
	,d.division_id
	,4 as retailer_id
	,ac.category_id
	,qty as units
	,(order_total  - rate_amount) * qty as sales
	,8 as sale_type_id
	,order_date as date_shipped
	,group_id
	,ac.account_manager_id
	,cbm_id
	,group_id_id
from pos_reporting.dsv_orders_3p_recon r
left join clean_data.master_com_list mcl
on r.item_id = mcl.item_id
left join cat_by_model cbm 
on r.model = cbm.model
left join account_manager_cat ac
on cbm.cat = ac.category_name
left join divisions d 
on d.division_name = mcl.division
left join group_ids g 
on r.item_id = g.tool_id
left join power_bi.dim_ships_item_id i
on r.item_id::text = i.item_id
left join power_bi.dim_models m 
on r.model = m.model_name
left join power_bi.dim_product_names p
on r.product_name = p.product_name
where status !='Refund'
)
;
