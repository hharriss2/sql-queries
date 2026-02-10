--shipment sales coming form the jde database that are reworked to match historical shipments on DHF side
create or replace view walmart.core.ships_jde as 
(
with t1 as 
( --base query david green sent over 
SELECT
    sh.kcoo_companykeyorderno as company_number
    ,sh.doco_documentorderinvoicee as order_number
    ,sh.dcto_ordertype as order_type
    ,sh.lnid_linenumber as line_number
    ,sh.gl_yearid as gl_year
    ,month(sh.dtforglandvouch1) as gl_month
    ,sh.dtforglandvouch1 as date_shipped
    ,sh.daterequested as requested_ship_date
    ,sh.datetransaction as transaction_date
    ,sh.actualshipdate as actual_date_shipped
    -- warehouse data
    ,sh.mcu_costcenter as warehouse_code
    ,bu.dl01_description001 as warehouse_desc
    -- customer data
    ,sh.an8_addressnumber as jde_billto_acct_number
    ,abbt.alky_alternateaddresskey as mapics_bt_acct_number
    ,cm.customername as billto_acct_name
    ,cm.ac12_reportcodeaddbook012 as retailer_code
    ,cm.ac12_reportcodeaddbook012_desc1 as retailer_code_desc
    ,cm.ac11_reportcodeaddbook011 as retailer_sale_type_code
    ,cm.ac11_reportcodeaddbook011_desc1 as retailer_sale_type_desc
    ,cm.country as customer_country
    ,sh.shan_addressnumbershipto as jde_shipto_acct_number
    ,abst.alky_alternateaddresskey as mapics_st_acct_number
    ,abst.alph_namealpha as shipto_account_name
    ,coalesce(mrl.hf_customer,mrl.jde_customer_name,shipto_namemailing) as customer_name

    -- item data
    ,sh.litm_identifier2nditem as item_number
    ,coalesce(di.product_name,im2.itemdesc) as item_desc1 -- item_name
    ,sh.dsc2_descriptionline2 as item_desc2
    ,im.itm_identifiershortitem as item_identifier
        --coalesce for dhp item list. if not use jde list
    ,coalesce(di.category,im.supergroup_desc1) as item_category -- category
    ,coalesce(di.department,im.ultragroup_desc1) as item_grouping --department
    ,im.srp7_salesreportingcode7 as brand_code
    ,coalesce(di.brand_name,im.srp7_salesreportingcode7_desc1) as brand_desc -- brand
    ,im2.branddesc2 as consolidated_brand_desc
    ,im2.upcn_upcnumber as upc_code

    -- sales metrics
    ,sh.uorg_unitstransactionqty as ordered_quantity
    ,sh.soqs_unitsquantityshipped as shipped_quantity
    ,sh.uprc_amtpriceperunit2 as unit_price
    ,sh.aexp_amountextendedprice as extended_price
    ,sh.uncs_amountunitcost as unit_cost
    ,sh.ecst_amountextendedcost as extended_cost

    -- canadian dollar metrics if the customer is cad
    ,sh.crr_currencyconverrateov as currency_conversion_rate
    ,sh.fup_amtforpriceperunit as foreign_price_per_unit
    ,sh.fuc_amountforeignunitcost as foreign_cost_per_unit
    ,sh.fea_amountforeignextprice as foreign_extended_price
    ,sh.fec_amountforeignextcost as foreign_extended_cost
    /* adding a composite key*/
    ,order_number ||'-'||line_number::numeric(10,0) as order_id
    ,mrl.hf_customer_number
    ,mrl.hf_pricing_type
    ,mrl.jde_customer_no
    ,di.division_name
    ,mrl.passport_retailer
    

FROM djus_jde_shared.public.ODS_F42119_SALES_HISTORY SH -- sales order history, stuff that has gone to GL (has gl date) or been canceled (has no gl date)
         JOIN djus_jde_shared.public.ODS_F03012_CUSTOMER_MASTER_LOB CM
              ON CM.CO_COMPANY = SH.KCOO_COMPANYKEYORDERNO 
              AND CM.AN8_ADDRESSNUMBER = SH.AN8_ADDRESSNUMBER
         JOIN djus_jde_shared.public.ODS_F0101_ADDRESS_BOOK_MASTER ABBT -- Address Book Table Joined on the BillTo account number
              ON ABBT.AN8_ADDRESSNUMBER = SH.AN8_ADDRESSNUMBER
         JOIN djus_jde_shared.public.ODS_F0101_ADDRESS_BOOK_MASTER ABST -- Address Book Table Joined on the ShipTo account number
              ON ABST.AN8_ADDRESSNUMBER = SH.SHAN_ADDRESSNUMBERSHIPTO
         LEFT JOIN djus_jde_shared.public.ODS_F4101_ITEM_MASTER IM -- Item Master Table for anything you need out of there
                   ON IM.ITM_IDENTIFIERSHORTITEM = SH.ITM_IDENTIFIERSHORTITEM
         LEFT JOIN djus_jde_shared.PUBLIC.ODS_MSD_ITEM_COMPLETE IM2 -- Curated Item Master Table for better reporting
                   ON IM2.ITEMID = SH.ITM_IDENTIFIERSHORTITEM
        left join djus_jde_shared.public.ods_f0006_business_unit_master bu
            on bu.co_company = sh.kcoo_companykeyorderno
            and bu.mcu_costcenter = sh.mcu_costcenter
        left join walmart.components.monday_retailer_list mrl
        on cm.an8_addressnumber::text = mrl.jde_customer_no
        left join walmart.dim_sources.dim_cat_by_model di -- item table from dhps items
        on sh.litm_identifier2nditem = di.model
WHERE 1=1
-- and sh.dtforglandvouch1 >= '2025-12-08' -- starting orders where shipments left off
AND SH.KCOO_CompanyKeyOrderNo IN ('00100', '00400')
AND SH.DCTO_OrderType NOT IN (SELECT ORDER_TYPE FROM djus_jde_shared.PUBLIC.JDE_SALES_ORDER_TYPE_EXCLUSIONS)
AND SH.LNTY_LineType IN (SELECT LINE_TYPE FROM djus_jde_shared.PUBLIC.JDE_SALES_LINE_TYPE_INCLUSIONS)
  AND (IM.SRP1_SALESREPORTINGCODE1 = 'DHF'
    OR CM.AC17_REPORTCODEADDBOOK017 BETWEEN '100' AND '299') -- DHF or DHF-related customer
and BILLTO_ACCT_NAME  not in ('Dorel Juvenile Group (No charge)') -- bill to accounts not to include in ships
and SHIPPED_QUANTITY >0
and sh.DCTO_ORDERTYPE Not In ('C1', 'SV', 'SG', 'KP', 'SH')
and sh.lnty_linetype in ('D', 'S', 'S7','VC','W')
)
,fix_retailers as 
( -- fixing the walmart and amazon retailer names for easier categorization
select *
,case
    when jde_customer_no is not null then hf_pricing_type
    when BILLTO_ACCT_NAME like '%DSV%' then 'Drop Ship'
    when BILLTO_ACCT_NAME like '% DI %' then 'Direct Import'
    when BILLTO_ACCT_NAME = 'Walmart L DH' then 'Brick & Mortar'
    when BILLTO_ACCT_NAME like '%Bulk%' then 'Bulk'
    when lower(BILLTO_ACCT_NAME) like '%import%' then 'Direct Import'
    when BILLTO_ACCT_NAME like '% B2C %' then 'Marketplace'
    when retailer_sale_type_code = '280' then 'Drop Ship'
    else 'Brick & Mortar'
    end as sale_type
,case
    when jde_customer_no is not null then passport_retailer
    when customer_country = 'US' and BILLTO_ACCT_NAME like '%Walmart%'
    then
        case
        when sale_type = 'Brick & Mortar' then 'Walmart Stores'
        when sale_type = 'Drop Ship' then 'Walmart.com'
        when BILLTO_ACCT_NAME like '%Bulk DI%' then 'Walmart.com'
        when BILLTO_ACCT_NAME like '%Bulk%' then 'Walmart.com'
        when BILLTO_ACCT_NAME like '% DI %' then 'Walmart Stores'
        when sale_type = 'Marketplace' then 'Walmart DHF Direct'
        end
    when customer_country = 'CA' and BILLTO_ACCT_NAME like '%Walmart%'
    then
        case
        when sale_type = 'Brick & Mortar' then 'Walmart Canada'
        when sale_type = 'Drop Ship' then 'Walmart.ca'
        when BILLTO_ACCT_NAME like '%Bulk DI%' then 'Walmart.ca'
        when BILLTO_ACCT_NAME like '%Bulk%' then 'Walmart.ca'
        when BILLTO_ACCT_NAME like '% DI %' then 'Walmart Canada'
        when sale_type = 'Marketplace' then 'Walmart.da Direct'
        end
    when customer_country = 'CA' and BILLTO_ACCT_NAME like '%Amazon%'
    then
        case
        when sale_type = 'Drop Ship' then 'Amazon.com.ca'
        when sale_type = 'Direct Import' then 'Amazon.com.ca'
        when sale_type = 'Marketplace' then 'Amazon Direct ca'
        end
    when customer_country = 'US' and BILLTO_ACCT_NAME like '%Amazon%'
    then
        case
        when sale_type = 'Drop Ship' then 'Amazon.com'
        when sale_type = 'Direct Import' then 'Amazon.com'
        when sale_type = 'Marketplace' then 'Amazon Direct'
        end
    else BILLTO_ACCT_NAME
    end as retailer
from t1
-- where lower(BILLTO_ACCT_NAME) like '%amazon%'
)
,check_retailer_names as 
( -- not used in the main query. used to see if the column 'retailer' has the correct names
select distinct BILLTO_ACCT_NAME
    ,SHIPTO_ACCOUNT_NAME
    ,sale_type
    ,retailer_code_desc
    ,retailer_sale_type_code
    ,retailer_sale_type_desc
    ,customer_country
    ,retailer
from fix_retailers
-- where lower(BILLTO_ACCT_NAME) like '%amazon%'
)
,details as 
( --finalized shipment template for the postgres db shipments
select item_number as model
    ,date_shipped
    ,upc_code as upc
    ,sale_type
    ,item_desc1 as product_name
    ,item_category as category
    ,item_grouping as department
    ,SHIPPED_QUANTITY as units
    ,unit_price * SHIPPED_QUANTITY as sales
    ,division_name as division
    ,retailer
    ,order_id
    ,warehouse_code
    ,hf_customer_number
    ,jde_customer_no
    ,brand_desc as brand
    ,customer_name
from fix_retailers
)
select 
    model
    ,date_shipped
    ,upc
    ,sale_type
    ,product_name
    ,category
    ,department
    ,sum(units) as units
    ,sum(sales) as sales
    ,division
    ,retailer
    ,order_id
    ,warehouse_code
    ,hf_customer_number
    ,jde_customer_no
    ,customer_name
    ,brand
from details
group by all 

--f4211 --for orders
--42119 -- for historicals

--go by gl date for shipments?? 
--date requested is used in open orders because they don't have one there
--date requested for open orders 
--gl date for shipments.
)
;