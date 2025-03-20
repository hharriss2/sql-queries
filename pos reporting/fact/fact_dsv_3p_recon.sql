--fact table for the dsv 3p recon report on power bi
create or replace view power_bi.fact_dsv_recon_3p as 
(
with oz as  --origin zone
(-- find the origin state for items shipped
select distinct state
,statefullname as state_name
,zipcode
from zipcodes 
)
,dl as --disco list
( -- returns items that are in the discontinued list of products
select *
from lookups.internal_item_status_view
where item_status in 
('Production - Obsolete','Production - Site Closeout') -- these statuses are considered 'Disco'
)
,td as  --time diff
( -- finding the number of days and hours it takes for an item to go from order to shipped
select sku as model
	,shipped_on - order_date as order_to_shipped_time_diff
from pos_reporting.dsv_orders_3p
where shipped_on is not null
)
,ai as --average item
( -- take the average time for the time diff clause per item
select model
	,avg(order_to_shipped_time_diff)::interval as avg_time_to_ship
from td
group by model
)
,iinv as --internal inventory. inventory dorel has
(
select
	model
	,sum(quantity_on_hand) as quantity_on_hand
	,sum(open_order_quantity) as open_order_quantity
	,sum(po_quantity) as po_quantity
from inventory.sf_item_inventory
group by model
)
,eif as --ecomm inventory feeds 
( -- feeds from dorel that show the ecommerce inventory feeds
select model
	,sum(feed_quantity) as feed_quantity
from inventory.sf_ecomm_inventory_feeds eif
where retailer_name = 'Walmart DHF Direct'
group by model
)
select
	dr.dsv_order_id
	,dr.po_id
	,dr.tracking_number
	,cal.wmcal_id
	,dm.model_id
	,di.item_id_id
	,cbm.cbm_id
	,g.group_id_id
	,amc.account_manager_id
	,dp.product_name_id
	,os.order_status_id
	,dr.qty
	,dr.order_total
	,dr.commission_amt
	,dr.rate_amount
	,dr.state_abr
	,dr.state_name
    ,dr.is_suppression_model
	,oz.state as origin_state_abr
	,oz.state_name as origin_state_name
	,shipped_on::date - order_date::date as  ordered_to_ship_days
	,delivered_on::date - shipped_on::date as shipped_to_delivered_days
	,delivered_on::date -  order_date::date as ordered_to_delivered_days
	,case -- shows if model is on disco or not
		when dl.model is not null
		then 1
		else 0
		end as is_disco
	,coalesce(ai.avg_time_to_ship,est_ship_date::timestamp - order_date_time) as avg_time_to_ship
	,current_date - dr.order_date_time as current_time_without_ship
	--^ if there isn't a average for the item, use the estimated ship date
	,case -- the current time for the shipped date is 1 day after the average
		when dr.status = 'Acknowledged'
			and order_date >='2024-10-20' 
			and current_date - dr.order_date_time
			>=coalesce(ai.avg_time_to_ship,est_ship_date::timestamp - order_date)
		then 1
		else 0
		end as past_avg_time_flag
	,case -- so we know if the past avg time flag is going off of the estimated ship date or the actual avg time to ship
		when ai.avg_time_to_ship is null
		then 0
		else 1
		end as has_avg_time_to_ship
    ,iinv.quantity_on_hand
    ,iinv.open_order_quantity
    ,iinv.po_quantity
    ,eif.feed_quantity
from pos_reporting.dsv_orders_3p_recon dr
left join oz 
on oz.zipcode = dr.origin_postal_code
left join dim_sources.dim_models dm
on dr.model = dm.model_name
left join dim_sources.dim_wm_item_id di
on dr.item_id = di.item_id
left join dim_sources.dim_product_names dp
on dr.product_name = dp.product_name
left join power_bi.wm_calendar_view cal
on dr.order_date = cal.date 
left join dim_sources.dim_order_status os
on dr.status = os.order_status_name
left join cat_by_model cbm
on dr.model = cbm.model
left join account_manager_cat amc 
on cbm.cat = amc.category_name
left join power_bi.group_id_view g
on dr.item_id = g.tool_id
left join dl
on dr.model = dl.model
left join ai
on ai.model = dr.model
left join iinv
on dr.model = iinv.model
left join eif
on dr.model = eif.model
where dr.status !='Refund'
)
;