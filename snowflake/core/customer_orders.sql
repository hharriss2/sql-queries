--shows the customer orders for dhp
create or replace view walmart.core.customer_orders as 
(
with cd as --customer deduction
(
select distinct  customer_number
    ,deduction_percent
from walmart.components.customer_deductions
)
select
    daterequested as date_requested -- the date where customers requested for their items to be shipped
    ,oo.datetransaction as transaction_date -- date order is asked for
    ,oo.doco_documentorderinvoicee as order_number
    ,oo.an8_addressnumber -- customer number on juvenile side
    ,mrl.hf_customer -- customer number on dh side
    ,mrl.hf_customer_number
    ,cm.customername as jde_customer_name -- customer name on juvenile side
    ,coalesce(mrl.hf_customer,cm.customername) as customer_name -- priority takes dhf name, then juv is no name availabke
    ,oo.litm_identifier2nditem as model_number -- model number
    ,cbm.division_name -- division
    ,dw.warehouse_number -- warehouse
    ,dw.warehouse_name -- warehouse name
    ,dcto_ordertype_desc1 order_type
    ,lttr_statuscodelast_desc1 as last_status_code -- the current status code
    ,nxtr_statuscodenext_desc1 as next_status_code -- the status code we expect for an item to be in next
    --^ when next status code gets to 620, it gets to be shipped
    ,uorg_unitstransactionqty as units_transaction -- amount requested for transaction
    --^ users like the transaction qty aka 'ordered qty'. shows us what we plan to ship. If theres inv shortnesses, ez to spot this way
    ,soqs_unitsquantityshipped as quantity_shipped -- amout we're actually shipping
    ,uprc_amtpriceperunit2 as price_per_unit -- gross / units
    ,soqs_unitsquantityshipped * uprc_amtpriceperunit2 as gross_sales -- total sales amount
    --^ this is to find the actual amount shipped. using the 'extended price', you only get to see what is 'expected' to be shipped
    ,uncs_amountunitcost as unit_cost_amount -- cost for the item
    ,soqs_unitsquantityshipped * uncs_amountunitcost as sales_cost --  total cost
    ,gross_sales - sales_cost as standard_cost -- gross sales minus the cost for standard cost
    ,(ad.total_coop_adv_percent + ad.total_ra_percent) * -1 as total_deduction_percent
    ,coalesce( -- 
        gross_sales + (gross_sales * total_deduction_percent)
        ,gross_sales + (gross_sales * cd.deduction_percent)
     ) as net_sales
    ,shpn_shipmentnumber as shipment_number -- i think it's a container number
from djus_jde_shared.public.ods_f4211_open_orders oo
left join djus_jde_shared.PUBLIC.ODS_MSD_ITEM_COMPLETE im
on oo.itm_identifiershortitem::text = im.itemid
left join walmart.components.monday_retailer_list mrl
on oo.an8_addressnumber::text = mrl.jde_customer_no
left join walmart.dim_sources.dim_cat_by_model cbm
on oo.litm_identifier2nditem = cbm.model
left join walmart.dim_sources.dim_warehouses dw
on oo.mcu_costcenter = dw.warehouse_number
JOIN djus_jde_shared.public.ODS_F03012_CUSTOMER_MASTER_LOB CM
  ON CM.CO_COMPANY = oo.KCOO_COMPANYKEYORDERNO 
  AND CM.AN8_ADDRESSNUMBER = oo.AN8_ADDRESSNUMBER
left join djus_jde_shared.public.ods_dhf_sales_acct_deductions ad
on ad.billto_account_id::text = cm.AN8_ADDRESSNUMBER
left join cd
on mrl.hf_customer_number = cd.customer_number
where 1=1
and im.divisioncode = 'DHF' -- only dorel home items
and oo.KCOO_CompanyKeyOrderNo IN ('00100', '00400') -- customer must be within this range 
and cm.customername !='Dorel Juvenile Group (No charge)' -- dismissing the juvenile sstuff
and CM.AC17_REPORTCODEADDBOOK017 BETWEEN '100' AND '299' -- customer number must be within  this range
and lttr_statuscodelast_desc1 !='Canceled in Order Entry' -- not recording canceled orders
-- and OO.NXTR_StatusCodeNext < '620'-- if the next status the item goes in is 620 or higher, it's being entered as a journal update, cancelating, or a system purge 
)
;