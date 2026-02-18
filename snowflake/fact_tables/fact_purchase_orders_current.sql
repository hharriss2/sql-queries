--finds purchase orders for factories. not that relevant. Customer purchase orders fact table is what is used on DHF shipment table
create or replace view walmart.power_bi.fact_purchase_orders_current as 
(
select
    cbm.cbm_id
    ,dd.division_id
    ,dst.stocking_type_id
    ,dw.warehouse_id
    ,dpn.product_name_id
    ,dv.vendor_id
    ,last_status_code
    ,last_status_desc
    ,next_status_code
    ,next_status_code_desc
    ,order_type
    ,order_type_description
    ,po_quantity
    ,ext_price
    ,ext_std_cost
    ,due_date
    ,dcal.cal_id
    ,container_id
    ,route_code
    ,route_code_description
from walmart.core.purchase_orders_current_day po
left join walmart.dim_sources.dim_cat_by_model cbm -- model, category, and deparmtent dim table
on po.item_id = cbm.model
left join walmart.dim_sources.dim_product_name dpn --product name
on po.item_description = dpn.product_name
left join walmart.dim_sources.dim_calendar dcal -- calendar
on po.due_date = dcal.cal_date
left join walmart.dim_sources.dim_warehouses dw --dim warehouses
on po.warehouse_code = dw.warehouse_number
left join walmart.dim_sources.dim_division dd -- division
on po.division = dd.division_name
left join walmart.dim_sources.dim_stocking_type dst -- stocking type
on po.stocking_type = dst.stocking_type_name
left join walmart.dim_sources.dim_vendor dv
on po.vendor_name = dv.vendor_name
)
;