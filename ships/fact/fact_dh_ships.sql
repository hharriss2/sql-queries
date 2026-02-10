--shipments from the ships table for dorel home
create or replace view power_bi.fact_dh_ships as 
(
with s as 
(
select
	id as ship_id
	,dm.model_id
	,date_shipped
	,st.sale_type_id
	,coalesce(msl.product_name, s.product_name) as product_name
	,coalesce(category,'') as category
	,coalesce(department,'') as department
	,sales
	,d.division_id
	,units
	,r.retailer_id
	,warehouse
	,bn.brand_id
	,wcv.wmcal_id
from ships_schema.ships s
left join clean_data.master_ships_list msl
on s.model = msl.model
left join dim_sources.dim_brand_name bn
on msl.brand_name = bn.brand_name
left join power_bi.wm_calendar_view wcv
on s.date_shipped = wcv.date
left join divisions d
on s.division = d.division_name
left join sale_type st
on st.sale_type = s.sale_type
left join retailer r 
on s.retailer = r.retailer_name
left join dim_sources.dim_models dm
on s.model = dm.model_name
where 1=1
and date_shipped >='2023-01-01'
)
select ship_id
	,model_id
	,date_shipped
	,sale_type_id
	,pn.product_name_id
	,sales
	,division_id
	,units
	,retailer_id
	,warehouse
	,brand_id
	,wmcal_id
	,cd.category_department_id
from s
left join dim_sources.dim_product_names pn
on s.product_name = pn.product_name
left join dim_sources.dim_category_department cd
on s.category ||'-'||s.department = cd.category_department
)
