--report used to replicate the daily report sent out every day
with sa as --stores aggregate
( -- aggregating units and sales for stores 
select
	vendor_nbr
	,prime_item_nbr
	,mcl.model
	,ls.unit_retail
	,ls.prime_item_desc
	,ls.vendor_stock_number
	,sum( -- week to date units
		case
		when wcal.is_current_wm_week =1  -- store sales are in current wm week
		then pos_qty
		else null end
		) as wtd_units
	,sum(-- week to date sales
		case 
		when wcal.is_current_wm_week =1  -- store sales are in current wm week
		then pos_sales
		else null end
		) as wtd_sales
	,sum( -- week to date for last year
		case 
		when wcal.is_current_wm_week_ly = 1 -- sales are in cyrrent week for last year
			and  wcal.wm_day_of_week <= wcal.current_wm_day_of_week - 1 -- sales are day behind, so find todays date minus a day
		then pos_qty
		else null end
		) as wtd_ly_units
	,sum(
		case 
		when wcal.is_current_wm_week_ly = 1
			and  wcal.wm_day_of_week <= wcal.current_wm_day_of_week - 1
		then pos_sales
		else null end
		) as wtd_ly_sales
	,sum 
		( -- sales for the previous walmart week
		case
		when wcal.previous_wm_week = 1
		then pos_qty
		else null end
		) as last_week_units
	,sum
		( -- sales for the previous 4 walmart weeks, not including the current
		case
		when wcal.is_last_4_weeks = 1
		then pos_qty
		else null end 
		) as last_4_weeks_units
--	,-- avg weekly pos qty = l4 weeks divided by 4
	,sum
		( -- year to date sales in units
		case
		when wcal.is_ytd_wm_week =1
		then pos_qty
		else null end
		) as ytd_units
	,sum
		( -- year to date sales in dollar
		case
		when wcal.is_ytd_wm_week =1 
		then pos_sales
		else null end
		) as ytd_sales
from sales_stores_auto ssa
left join clean_data.master_com_list mcl
on ssa.prime_item_nbr::bigint = mcl.item_id
left join power_bi.wm_calendar_view wcal 
on ssa.daily = wcal.date
left join pos_reporting.lookup_stores ls
on ssa.prime_item_nbr::bigint = ls.prime_item_num
where 1=1
and daily is not null
and prime_item_nbr = '550955318'
--and daily >= current_date - interval '400 days'
group by vendor_nbr
	,prime_item_nbr
	,mcl.model
	,ls.prime_item_desc
	,ls.vendor_stock_number
	,ls.unit_retail
)
,sia as --stores inventory aggregate
(
select
	prime_item_nbr
	,sum(on_hand_qty) as store_on_hand
	,sum(in_warehouse_qty) as store_in_warehouse
	,sum(in_transit_qty) as store_in_transit
	,sum(on_hand_qty) 
	+ sum(in_warehouse_qty)
	+ sum(in_transit_qty)
	 as store_inventory
from pos_reporting.inventory_stores
group by prime_item_nbr
)
,wia as --warehosue inventory aggregate
(
select 
	walmart_item_number
	,sum(w.on_hand_warehouse_inventory_in_units_this_year) as warehouse_inventory
from inventory.wm_warehouse_on_hands w
group by walmart_item_number
)
select
	sa.vendor_nbr
	,sa.prime_item_nbr
	,vendor_stock_number
	,sa.model
	,sa.prime_item_desc
	--status
	--pack size
	--special buy
	--item type code
	,sa.unit_retail
	,cast(ytd_sales/ ytd_units as numeric(10,2)) as average_retail
	--unit cost
	--landed cost
	,wtd_units --wtd pos qty
	,wtd_ly_units --ly wtd pos qty
	,cast((wtd_units - wtd_ly_units)/nullif(wtd_ly_units::numeric(10,2),0) as numeric(10,2)) as ly_wtd_pos_units_change
	--^last wtd pos qty % change (current wtd - ly wtd) / ly wtd
	,last_week_units
	,last_4_weeks_units -- l4 wks pos qty
	,last_4_weeks_units::numeric(10,2)/4 as average_weekly_units --avg weekly pos qty
	,ytd_sales --ty fytd pos sales
	,wtd_sales --wtd pos sales
	,wtd_ly_sales --ly wtd pos sales
	,cast((wtd_sales - wtd_ly_sales)/nullif(wtd_ly_sales::numeric(10,2),0) as numeric(10,2)) as ly_wtd_pos_sales_change
	--^ ly wtd pos $ % change (current wtd - ly wtd) / ly wtd
	,store_inventory --inventory in store
	,wia.warehouse_inventory -- inventory in warehouse
	,coalesce(store_inventory::numeric(10,2)/nullif(last_week_units,0),0) as weeks_of_supply_lw
	--wks of supply based on lw pos qty =  inventory divided by total units sold last week
	,coalesce(store_inventory::numeric(10,2)/nullif(last_4_weeks_units/4,0),0) as weeks_of_supply_l4
	--wkes of supply based on l4 wks avg pos qty
	-- need curr traited store count
	--need ly store count
	--replin instock
	--replin instock last year
	--wtd sales per traited stores
	--wtd units per traited stores
from sa
left join sia
on sa.prime_item_nbr::bigint = sia.prime_item_nbr
left join wia
on sa.prime_item_nbr::bigint = wia.walmart_item_number
;