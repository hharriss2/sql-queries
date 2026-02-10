
-- compares the data_dump.csv files we get from walmart to our inventory & feeds
--will have power bi report called 'WM Inventory Report' in the Dorel BV workspace
--also will have pipedream report that emails out this file
create or replace view power_bi.fact_wm_inventory_report as 
( 
with dc as --date compare
(
select vendor_nbr_9, max(inserted_at::date) as date_compare
from inventory.wm_ladder_inventory
group by vendor_nbr_9
)
,wmi as --walmart inventory
(-- file is from walmart emails labled 'data_dump.csv'
 select
channel_type -- retailer is wm com or stores
,walmart_item_number
,cid -- item id
,coalesce(mcl.model,mcl2.model) as model -- internal model
,wid.prime_item_desc -- item description
,wid.on_hand_1_qty-- inventory levels
,wid.in_transit_qty
,wid.on_order_qty
,coalesce(wid.on_hand_1_qty,0)
	+coalesce(wid.in_transit_qty,0)
	+coalesce(wid.on_order_qty,0)
 as total_inv_qty --total inventory
,wid.whs_on_hand
,wid.in_whs_qty as fc_in_network_qty
,wid.whs_on_order
,coalesce(wid.whs_on_hand,0)
    +coalesce(wid.in_whs_qty,0)
	+coalesce(wid.whs_on_order,0)
 as fc_total -- total facility 
,coalesce(wid.on_hand_1_qty,0)
	+coalesce(wid.in_transit_qty,0)
	+coalesce(wid.on_order_qty,0)
	+coalesce(wid.whs_on_hand,0)
	+coalesce(wid.in_whs_qty ,0)
	+coalesce(wid.whs_on_order,0)
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
,mcl.division
--find the last 3 weeks average units for pos
from inventory.wm_ladder_inventory wid
join dc
on wid.vendor_nbr_9 = dc.vendor_nbr_9
and wid.inserted_at::date = dc.date_compare
left join clean_data.master_com_list mcl
on wid.cid = mcl.item_id
left join clean_data.master_com_list mcl2
on wid.walmart_item_number = mcl2.item_id
left join cat_by_model cbm
on mcl.model = cbm.model

where 1=1 
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
,ecomm_l4 as -- last 4 weeks for ecomm units 
(	
select item_id
,sum(
	case
	when wc.is_last_4_weeks =1
	then r.units
	else 0 end
	) as last_4_weeks_units
,sum(
	case
	when wc.is_last_3_weeks = 1
	then r.units
	else 0 end
	)/3 as l3_week_avg_units
from retail_link_pos r
join power_bi.wm_calendar_view wc
on r.sale_date = wc.date
where 1=1
and item_id in (select cid from inventory.wm_ladder_inventory) -- filter down the pos data
and item_type !='3P'
-- and wc.is_last_4_weeks = 1 -- filter down for only last 4 weeks pos
group by item_id
)
,stores_l4 as 
(
select item_id as walmart_item_number
,sum(
	case
	when wc.is_last_4_weeks =1
	then ssa.pos_qty
	else 0 end
	) as last_4_weeks_units
,sum(
	case
	when wc.is_last_3_weeks = 1
	then ssa.pos_qty
	else 0 end
	)/3 as l3_week_avg_units
from pos_reporting.wm_stores_pos ssa
join power_bi.wm_calendar_view wc
on ssa.sale_date = wc.date
where 1=1
and item_id::bigint in (select walmart_item_number from inventory.wm_ladder_inventory)
group by item_id
)
,sfc as --store forecast
( -- get the next 13 weeks for the stores forecast
select
	prime_item_number as walmart_item_number
	,sum(forecast_quantity) as forecast_n13w
from forecast.wm_store_forecast
group by prime_item_number
)
,ecomm_fc as --ecomm forecast
( --get the next 13 weeks for the ecomm forecast
select 
	item_id
	,sum(units) as forecast_n13w
from forecast.wm_ladder_forecast
where inserted_at::date = (select max(inserted_at::date) from forecast.wm_ladder_forecast)
and wm_date in --wm date must be in the next 13 weeks
	(
	select distinct wm_date 
	from wm_calendar
	where date > current_date +interval '1 week'
	and wm_date is not null
	order by wm_date 
	limit 13
	)
group by item_id
)

--all the details put together
select
	wmi.channel_type
	,wmi.walmart_item_number
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
	,case
		when channel_type = 'WMT.COM'
		then cast(wmi.on_hand_1_qty / nullif(ecomm_l4.l3_week_avg_units,0) as integer) 
		else cast(wmi.on_hand_1_qty / nullif(stores_l4.l3_week_avg_units,0) as integer) 
		end as wm_wks_oh
	--weeks on hand
	,ei.available_to_sell
	,case
		when channel_type = 'WMT.COM'
		then cast(ei.available_to_sell/ nullif(ecomm_l4.l3_week_avg_units,0) as integer) 
		else cast(ei.available_to_sell/ nullif(stores_l4.l3_week_avg_units,0) as integer) 
		end as dorel_wks_oh
	,ef.dsv_feed_qty as sum_of_dsv_feed
	,wmi.is_import
	,wmi.replinishment_flag
	,wmi.category
	,wmi.vendor_nbr_9
	,current_date as todays_date
	,wmi.inventory_event_code 
	,case -- solving the weeks on hand
	--first see if the retailer is ecomm or stores
	--next, if the last 4 weeks units sold for each of them is <0, then 0 out the WOS
	--otherwise, do (store + warehouse inventory) / ( (n13w fc + l4wk units)/17 ) 
		when channel_type = 'WMT.COM'
		then 
			case
			when ecomm_l4.last_4_weeks_units <0
			then 0
			else
			coalesce(
			(on_hand_1_qty::numeric(10,2) + whs_on_hand)/nullif((ecomm_fc.forecast_n13w +ecomm_l4.last_4_weeks_units)/17,0)
			,0)
			end
		when channel_type = 'Walmart stores'
		then 
			case
			when stores_l4.last_4_weeks_units <0
			then 0
			else 
			coalesce(
			(on_hand_1_qty::numeric(10,2) + whs_on_hand)/nullif((sfc.forecast_n13w +stores_l4.last_4_weeks_units)/17,0)
			,0)
			end
		end as weeks_of_supply_inventory_warehouse
		,wmi.division
from wmi
left join ecomm_inv ei
on wmi.model = ei.model
left join ecomm_feed ef
on wmi.model = ef.model
left join ecomm_l4
on wmi.cid = ecomm_l4.item_id
left join stores_l4
on wmi.walmart_item_number = stores_l4.walmart_item_number
left join sfc
on wmi.walmart_item_number = sfc.walmart_item_number
left join ecomm_fc
on wmi.cid = ecomm_fc.item_id
where 1=1
)

;

