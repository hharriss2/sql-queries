--warehouse PO's
create or replace view walmart.core.purchase_orders_current_day as 
(
select 
    im.division
    ,im.branddesc2 as brand_name
    ,im.ultradesc as ultra_group -- highest category 
    ,im.superdesc as super_group -- 2nd highest category
    ,im.stockingtypedesc as stocking_type
    ,im.platformdesc as platform_description
    ,im.salescatalogsubsectioncode as catalog_code -- shows nationality for item
    ,im.categorydesc as category_description
    ,im.subcategorydesc as sub_category_description
    ,cus.ac30_categorycodeaddressbk30_desc1 as customer_name
    ,mcu_costcenter as warehouse_code
    ,litm_identifier2nditem as item_id
    ,im.itemdesc as item_description
    ,po.vendorname as vendor_name
    ,po.lttr_statuscodelast as last_status_code
    ,po.lttr_statuscodelast_desc1 as last_status_desc
    ,po.nxtr_statuscodenext as next_status_code
    ,po.nxtr_statuscodenext_desc1 as next_status_code_desc
    ,po.dcto_ordertype as order_type
    ,po.dcto_ordertype_desc1 as order_type_description
    ,po.quantity as po_quantity -- as purchase order quantity
    ,po.extpurchprice as ext_price -- extended price
    ,po.extstdcost as ext_std_cost -- extended standard cost
    ,duedate as due_date
    ,duedate - interval '60 days' as est_arrival_date
    ,case
        when est_arrival_date <=current_date()
        and containerid =''
        then 'PO Passed Ship Date'
    end as is_passed_ship_date
    ,case
        when duedate - interval '30 days' <= current_date()
        and routecodedesc = 'Not Shipped'
        then 'Late Booking'
        end as is_late_booking
    ,po.containerid as container_id
    ,po.routecode as route_code
    ,po.routecodedesc as route_code_description
from djus_jde_shared.public.ODS_PO_RECEIPTS_SNAPSHOT po
left join djus_jde_shared.PUBLIC.ODS_MSD_ITEM_COMPLETE im
on po.itm_identifiershortitem = im.itemid
left join djus_jde_shared.public.ODS_F03012_CUSTOMER_MASTER_LOB cus
on po.kcoo_companykeyorderno = cus.co_company
and po.an8_addressnumber = cus.an8_addressnumber
where 1=1
and im.divisioncode = 'DHF' --dorel home furniture items only
)
;
