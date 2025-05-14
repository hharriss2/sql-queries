
-- compares the data_dump.csv files we get from walmart to our inventory & feeds
--will have power bi report called 'WM Inventory Report' in the Dorel BV workspace
--also will have pipedream report that emails out this file
create or replace view power_bi.fact_wm_inventory_report as 
( 
with wmi as --walmart inventory
(-- file is from walmart emails labled 'data_dump.csv'

 select
channel_type -- retailer is wm com or stores
,cid -- item id
,mcl.model -- internal model
,wid.prime_item_desc -- item description
,wid.on_hand_1_qty-- inventory levels
,wid.in_transit_qty
,wid.on_order_qty
,wid.on_hand_1_qty
	+wid.in_transit_qty
	+wid.on_order_qty
 as total_inv_qty --total inventory
,wid.whs_on_hand
,wid.in_whs_qty as fc_in_network_qty
,wid.whs_on_order
,wid.whs_on_hand
	+wid.in_whs_qty 
	+wid.whs_on_order
 as fc_total -- total facility 
,wid.on_hand_1_qty
	+wid.in_transit_qty
	+wid.on_order_qty
	+wid.whs_on_hand
	+wid.in_whs_qty 
	+wid.whs_on_order
as total_wm_inventory
,case -- if vendor number is either, then yes else not import
	when wid.vendor_nbr_9 in ('10337710','9517710')
	then 'Y'
	else 'N'
	end as is_import
,wid.item_replenishable_ind as replinishment_flag  
,(wid.lstwkpos + wid.l02wkpos + wid.l03wkpos) /3 as l3_week_avg_units 
,coalesce(cbm.cat, wid.category) as category
,wid.vendor_nbr_9
,item2_desc inventory_event_code
--find the last 3 weeks average units for pos
from inventory.wm_inventory_dump wid
left join clean_data.master_com_list mcl
on wid.cid = mcl.item_id
left join cat_by_model cbm
on mcl.model = cbm.model
where 1=1
and wid.inserted_at::date = (select max(inserted_at::date) from inventory.wm_inventory_dump) 
--select the most recent inventory report
)
,ecomm_inv as 
( -- inventory levels for wm.com 
select
	model
	,sum(quantity_on_hand) as ecomm_qty_on_hand
	,sum(on_water_quantity) as ecomm_qty_in_transit
	,sum(open_order_quantity) as ecomm_qty_open_order
	,sum(po_quantity) as ecomm_qty_factory_order
	,case
		when sum(quantity_on_hand) - sum(open_order_quantity) <0
		then 0
		else sum(quantity_on_hand) - sum(open_order_quantity)
		end as available_to_sell 
from inventory.sf_item_inventory
where 1=1
--and model = '8174335W'
and warehouse_number not in
(22,23,41,42,5,51,66,67,68,8,80,81,82,83,84,85,86,87,88,90)
--warehouses excluded from the report
group by model
)
,ecomm_feed_s1 as 
( -- step one for finding the wm.com feed from dorel
select model 
,feed_quantity
,date_updated
,row_number() over (partition by model, warehouse_number order by date_updated desc) as recent_feed_seq
--^transactional table that shows feeds for different days. this labels the most recent feed with a '1'
from inventory.sf_ecomm_inventory_feeds
where 1=1
--and model = '14678BLK1'
and warehouse_number::integer not in
(22,23,41,42,5,51,66,67,68,8,80,81,82,83,84,85,86,87,88,90)
--discarding warehouses from the report
and retailer_name = 'Walmart.com'
--only want walmart dsv 
and date_updated >= current_date::date - interval '1 week'
--if the feeds are olrder than a week (maybe even a day), assume the feeds are turned off
)
,ecomm_feed as
(--final step from query above

select model
	,sum(feed_quantity) as dsv_feed_qty -- total feed by model
from ecomm_feed_s1
where recent_feed_seq = 1 -- set to find the most recent feed
group by model
)
--all the details put together
select
	wmi.channel_type
	,wmi.model
	,wmi.cid
	,wmi.prime_item_desc
	,wmi.on_hand_1_qty as store_ecomm_oh
	,wmi.in_transit_qty as store_ecomm_in_transit
	,wmi.on_order_qty as store_ecomm_on_order
	,wmi.total_inv_qty as store_ecomm_total
	,wmi.whs_on_hand as fc_on_hand
	,wmi.fc_in_network_qty
	,wmi.whs_on_order as fc_on_order
	,wmi.fc_total
	,wmi.total_wm_inventory
	,cast(wmi.total_wm_inventory / nullif(l3_week_avg_units,0) as integer) as wm_wks_oh
	--weeks on hand
	,ei.available_to_sell
	,cast(ei.available_to_sell/ nullif(l3_week_avg_units,0) as integer) as dorel_wks_oh
	,ef.dsv_feed_qty as sum_of_dsv_feed
	,wmi.is_import
	,wmi.replinishment_flag
	,wmi.category
	,wmi.vendor_nbr_9
	,current_date as todays_date
	,wmi.inventory_event_code
from wmi
left join ecomm_inv ei
on wmi.model = ei.model
left join ecomm_feed ef
on wmi.model = ef.model
where 1=1
)
;