create or replace view walmart.core.inventory_snapshot_current_day as 
(
select
    iss.item_number
    ,im.itemdesc as item_description
    ,im.branddesc2 as brand_name
    ,im.ultradesc as ultra_group -- highest category 
    ,im.superdesc as super_group -- 2nd highest category
    ,im.stockingtypedesc as stocking_type
    ,im.platformdesc as platform_description
    ,im.salescatalogsubsectioncode as catalog_code -- shows nationality for item
    ,im.categorydesc as category_description
    ,im.subcategorydesc as sub_category_description
    ,iss.mcu_costcenter as mcu_cost_center
    ,iss.costcenterdesc as cost_center_description
    ,iss.uncs_amountunitcost as uncs_amount_unit_cost
    ,iss.lots_lotstatuscode -- H is for hold. blank is for approved
    ,iss.pqoh_qtyonhandprimaryun as qty_on_hand_primary_un
    ,iss.onhandextendedcost as on_hand_extended_cost
    ,iss.pbck_qtybackorderedinpri as qty_back_order
    ,iss.preq_qtyonpurchaseorderpr as qty_on_purchase_order
    ,iss.qwbo_quantityonworeceipt as qty_on_wo_receipt -- not sure. maybe without reciept?
    --need explination on these columns
    ,iss.ot1p_qty1otherprimaryun as qty_other_primary_un
    ,iss.ot2p_qty2otherprimaryun as qty_other_primary_un_2
    ,iss.ot1a_qtyotherpurchasing1 as qty_other_purchasing_1
    --end 
    ,iss.hcom_qtyhardcommitted as qty_hard_commited
    ,iss.pcom_quantitysoftcommitted as qty_soft_commited
    ,iss.fcom_qtyonfuturecommit as qty_future_commit
    ,iss.fun1_workordersoftcommit as work_orders_soft_commit
    ,iss.qowo_quantityonworkorder as qty_on_work_order
    ,iss.qttr_qtyintranprimaryun as qty_in_transit
    ,iss.qtin_qtyininspprimaryun as qty_in_insp -- quantity in insp??
    ,iss.qonl_quantityonloantoma as qty_on_loan
    ,iss.qtri_quantityinboundwareh as qty_in_bound_warehouse -- quantity coming to the warehouse
    ,iss.qtro_quantityoutboundware as qty_out_bound_warehouse -- quantity coming out of the warehouse
from djus_jde_shared.public.ODS_F41021_INVENTORY_SNAPSHOT_DAILY iss
left join djus_jde_shared.PUBLIC.ODS_MSD_ITEM_COMPLETE im
on iss.item_number = im.itemnumber
where 1=1
and divisioncode = 'DHF'
and iss.extractdate = current_date()
)
;
