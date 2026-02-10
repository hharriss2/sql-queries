--for snowflake power bi source. current dates inventories for items
create or replace view walmart.power_bi.fact_inventory_current as 
(
select
    cbm.cbm_id
    ,dpn.product_name_id
    ,stocking_type_id
    ,catalog_code
    ,dw.warehouse_id
    ,uncs_amount_unit_cost
    ,lots_lotstatuscode
    ,qty_on_hand_primary_un
    ,on_hand_extended_cost
    ,qty_back_order
    ,qty_on_purchase_order
    ,qty_on_wo_receipt
    ,qty_other_primary_un
    ,qty_other_primary_un_2
    ,qty_other_purchasing_1
    ,qty_hard_commited
    ,qty_soft_commited
    ,qty_future_commit
    ,work_orders_soft_commit
    ,qty_on_work_order
    ,qty_in_transit
    ,qty_in_insp
    ,qty_on_loan
    ,qty_in_bound_warehouse
    ,qty_out_bound_warehouse
    ,dcal.cal_id
from walmart.core.inventory_snapshot_current_day iss
left join walmart.dim_sources.dim_cat_by_model cbm -- model, category, and deparmtent dim table
on iss.item_number = cbm.model
left join walmart.dim_sources.dim_product_name dpn --product name
on iss.item_description = dpn.product_name
left join walmart.dim_sources.dim_calendar dcal -- calendar
on current_date() = dcal.cal_date
left join walmart.dim_sources.dim_warehouses dw --dim warehouses
on iss.mcu_cost_center = dw.warehouse_number
left join walmart.dim_sources.dim_stocking_type dst
on iss.stocking_type = dst.stocking_type_name
where 1=1
)
;
