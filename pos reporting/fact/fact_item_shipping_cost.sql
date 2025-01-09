--used for the DSV 3p Recon Report on the BV Workspace. Also included in bv workspace omni ships
--gives the sales team an Idea on item costing. finds the average shipping cost for all models
create or replace view power_bi.fact_item_shipping_cost as 
(

select 
	dm.model_id
	,wi.item_id_id as wm_item_id_id
	,pn.product_name_id
	,cbm.cbm_id
	,ac.account_manager_id
	,isc.length
	,isc.width
	,isc.height
	,isc.weight
	,avg(isc.base_residential_rate) as base_residential_rate
	,avg(isc.additional_weight_surcharge) as additional_weight_surcharge
	,avg(isc.oversize_surcharge) as oversize_surcharge
	,avg(isc.fuel_surcharge) as fuel_surcharge
	,avg(isc.additional_handle_surcharge) as additional_handle_surcharge
	,avg(isc.total_shipping_cost) as total_shipping_cost
	,isc.is_multi_box
	,case
			when sl.model is not null
			then 1
			else 0
			end as is_suppression_model
	,si.item_id_id as ships_item_id_id
from components.item_shipping_cost isc
left join clean_data.master_ships_list msl
on isc.model = msl.model
left join lookups.model_suppression_list sl
on isc.model = sl.model
left join cat_by_model cbm
on isc.model = cbm.model
left join dim_sources.dim_product_names pn
on msl.product_name = pn.product_name
left join dim_sources.dim_wm_item_id wi 
on msl.item_id = wi.item_id
left join dim_sources.dim_models dm
on isc.model = dm.model_name
left join account_manager_cat ac
on cbm.cat = ac.category_name
left join dim_sources.dim_ships_item_id si
on msl.item_id::text = si.item_id
group by dm.model_id
	,wi.item_id_id
	,pn.product_name_id
	,cbm.cbm_id
	,ac.account_manager_id
	,isc.length
	,isc.width
	,isc.height
	,isc.weight
	,si.item_id_id
    ,is_multi_box
    ,sl.model
)
;

	