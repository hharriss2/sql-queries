

--taking the main table and adding all the dim sources for power bi
create or replace view walmart.power_bi.fact_margin_actuals as 
(
select
    sale_date
    ,dim_cal.cal_id
    ,dim_div.division_id
    ,dim_mod.model_id
    ,dim_pn.product_name_id
    ,dim_cus.customer_id
    ,dim_st.sales_type_id
    ,dim_ret.retailer_id
    ,dim_rt.retailer_type_id
    ,dim_rg.retailer_group_id
    ,dim_dpt.department_id
    ,dim_cn.category_id
    ,dim_sc.sub_category_id
    ,dim_is.item_status_id
    ,dim_br.brand_id
    ,dim_coll.collection_id
    ,dim_wh.warehouse_id
    ,dim_vc.value_class_id
    ,wca.units_sold
    ,wca.gross_sales
    ,wca.deductions
    ,wca.net_sales
    ,wca.standard_cost
    ,wca.overhead_cost
    ,wca.material_cost
    ,wca.duty_cost
    ,wca.std_margin
    ,wca.variable_product_cost
    ,wca.contribution_magrgin
    ,wca.labor_cost
    ,wca.returns_defective
from walmart.core.margin_actuals wca
left join walmart.dim_sources.dim_division as dim_div -- division
on wca.division_name = dim_div.division_name
left join walmart.dim_sources.dim_model as dim_mod -- model
on wca.model_name = dim_mod.model_name
left join walmart.dim_sources.dim_product_name as dim_pn -- product name
on wca.product_name_detailed = dim_pn.product_name
left join walmart.dim_sources.dim_customer as dim_cus -- customer
on wca.customer_number = dim_cus.customer_number
left join walmart.dim_sources.dim_sales_type as dim_st --sale type
on wca.sales_type = dim_st.sales_type
left join walmart.dim_sources.dim_retailer as dim_ret -- retailer
on wca.retailer_name = dim_ret.retailer_name
left join walmart.dim_sources.dim_retailer_type as dim_rt --retailer type
on wca.retailer_type = dim_rt.retailer_type
left join walmart.dim_sources.dim_retailer_group as dim_rg -- retailer group
on wca.retailer_group = dim_rg.retailer_group
left join walmart.dim_sources.dim_department as dim_dpt --department
on wca.department_name = dim_dpt.department_name
left join walmart.dim_sources.dim_category as dim_cn --category
on wca.category_name = dim_cn.category_name
left join walmart.dim_sources.dim_sub_category as dim_sc -- sub category
on wca.subcategory_name = dim_sc.sub_category_name
left join walmart.dim_sources.dim_item_status as dim_is --item status
on wca.item_status = dim_is.item_status
left join walmart.dim_sources.dim_brands as dim_br --brands
on wca.brand = dim_br.brand_name
left join walmart.dim_sources.dim_collection as dim_coll --collection
on wca.collection_name = dim_coll.collection_name
left join walmart.dim_sources.dim_warehouse as dim_wh --warehouse
on wca.warehouse_number = dim_wh.warehouse_number
left join walmart.dim_sources.dim_value_class as dim_vc --value class
on wca.value_class = dim_vc.value_class
left join walmart.dim_sources.dim_calendar dim_cal
on wca.sale_date = dim_cal.cal_date
where 1=1
and sale_date >='2024-01-01'
)
;
