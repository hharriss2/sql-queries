

--taking the main table and adding all the dim sources for power bi
create or replace view walmart.power_bi.fact_margin_forecast as 
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
    ,wcf.units_sold
    ,wcf.gross_sales
    ,wcf.deductions
    ,wcf.net_sales
    ,wcf.standard_cost
    ,wcf.overhead_cost
    ,wcf.material_cost
    ,wcf.duty_cost
    ,wcf.std_margin
    ,wcf.variable_product_cost
    ,wcf.contribution_magrgin
    ,wcf.labor_cost
    ,wcf.returns_defective
from walmart.core.margin_actuals wcf
left join walmart.dim_sources.dim_division as dim_div -- division
on wcf.division_name = dim_div.division_name
left join walmart.dim_sources.dim_model as dim_mod -- model
on wcf.model_name = dim_mod.model_name
left join walmart.dim_sources.dim_product_name as dim_pn -- product name
on wcf.product_name_detailed = dim_pn.product_name
left join walmart.dim_sources.dim_customer as dim_cus -- customer
on wcf.customer_number = dim_cus.customer_number
left join walmart.dim_sources.dim_sales_type as dim_st --sale type
on wcf.sales_type = dim_st.sales_type
left join walmart.dim_sources.dim_retailer as dim_ret -- retailer
on wcf.retailer_name = dim_ret.retailer_name
left join walmart.dim_sources.dim_retailer_type as dim_rt --retailer type
on wcf.retailer_type = dim_rt.retailer_type
left join walmart.dim_sources.dim_retailer_group as dim_rg -- retailer group
on wcf.retailer_group = dim_rg.retailer_group
left join walmart.dim_sources.dim_department as dim_dpt --department
on wcf.department_name = dim_dpt.department_name
left join walmart.dim_sources.dim_category as dim_cn --category
on wcf.category_name = dim_cn.category_name
left join walmart.dim_sources.dim_sub_category as dim_sc -- sub category
on wcf.subcategory_name = dim_sc.sub_category_name
left join walmart.dim_sources.dim_item_status as dim_is --item status
on wcf.item_status = dim_is.item_status
left join walmart.dim_sources.dim_brands as dim_br --brands
on wcf.brand = dim_br.brand_name
left join walmart.dim_sources.dim_collection as dim_coll --collection
on wcf.collection_name = dim_coll.collection_name
left join walmart.dim_sources.dim_warehouse as dim_wh --warehouse
on wcf.warehouse_number = dim_wh.warehouse_number
left join walmart.dim_sources.dim_value_class as dim_vc --value class
on wcf.value_class = dim_vc.value_class
left join walmart.dim_sources.dim_calendar dim_cal
on wcf.sale_date = dim_cal.cal_date
where 1=1
and sale_date >='2024-01-01'
limit 1000
)
;
