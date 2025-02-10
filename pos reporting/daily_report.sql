--report used to replicate the daily report sent out every day
create or replace view pos_reporting.daily_report as 
(
with sa as --stores aggregate
( -- aggregating units and sales for stores 
select
	ls.current_item_num
	,mcl.model
	,ls.unit_retail
	,ls.prime_item_desc
	,ls.vendor_stock_number
    ,ls.is_special_buy
    ,ls.item_status
    ,ls.unit_cost
    ,ls.landed_cost
    ,vendor_nbr_dept
    ,coalesce(ls.pack_size,pt.vendor_pack_quantity) as vendor_pack_quantity
   ,max(pt.item_type_code) as item_type_code
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
    ,mcl.division
    ,cbm.cat
    ,cbm.sub_cat
from sales_stores_auto ssa

left join power_bi.wm_calendar_view wcal 
on ssa.daily = wcal.date
left join pos_reporting.lookup_stores ls
on ssa.prime_item_nbr::bigint = ls.prime_item_num
left join clean_data.master_com_list mcl
on ls.current_item_num::bigint = mcl.item_id
left join lookups.vendor_number_clean vnc
on ssa.vendor_nbr = vnc.vendor_nbr
left join lookups.store_pack_type_tbl pt
on pt.item_nbr = prime_item_nbr::bigint
left join cat_by_model cbm
on mcl.model = cbm.model
where 1=1
and daily is not null
and ls.is_daily_item =1
and ls.item_status not like '%Delete%'
-- and vendor_nbr_dept = '71' -- daily is only for department 71
-- and prime_item_nbr = '550955318'
--and daily >= current_date - interval '400 days'
group by 
	ls.current_item_num
    ,vendor_nbr_dept
	,mcl.model
	,ls.prime_item_desc
    ,ls.unit_cost
	,ls.vendor_stock_number
	,ls.unit_retail
    ,ls.is_special_buy
    ,ls.item_status
    ,ls.landed_cost
    ,coalesce(ls.pack_size,pt.vendor_pack_quantity)
--    ,coalesce(ls.item_type_code,pt.item_type_code)
    ,mcl.division
    ,cbm.cat
    ,cbm.sub_cat
)

,sia as --stores inventory aggregate
(
select
	all_links_item_number 
	,sum(on_hand_qty) as store_on_hand
	,sum(in_warehouse_qty) as store_in_warehouse
	,sum(in_transit_qty) as store_in_transit
	,sum(on_hand_qty 
	+ in_warehouse_qty
	+ in_transit_qty)
	 as store_inventory
	,sum(traited_store_count_this_year) as traited_store_count_this_year
	,sum(traited_store_count_last_year) as traited_store_count_last_year
	,max(curr_repl_instock) as curr_repl_instock
	,max(repl_instock_percentage_last_year ) as repl_instock_percentage_last_year 
from pos_reporting.inventory_stores
group by all_links_item_number
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
	-- sa.prime_item_nbr
    sa.current_item_num
	,vendor_stock_number
	,sa.model
	,sa.prime_item_desc
	,sa.item_status
	,sa.is_special_buy
	,sa.item_type_code
    ,sa.vendor_pack_quantity
	,sa.unit_retail
	,cast(ytd_sales/ ytd_units as numeric(10,2)) as average_retail
	,sa.unit_cost
	,sa.landed_cost
	,wtd_units --wtd pos qty
	,wtd_ly_units --ly wtd pos qty
	,cast((wtd_units - wtd_ly_units)/nullif(wtd_ly_units::numeric(10,2),0) as numeric(10,2)) as ly_wtd_pos_units_change
	--^last wtd pos qty % change (current wtd - ly wtd) / ly wtd
	,last_week_units
	,last_4_weeks_units -- l4 wks pos qty
	,last_4_weeks_units::numeric(10,2)/4 as average_weekly_units --avg weekly pos qty
    ,ytd_units
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
    ,sia.traited_store_count_this_year
	,sia.traited_store_count_last_year
	,sia.curr_repl_instock
	,sia.repl_instock_percentage_last_year 
    ,cast(wtd_units::numeric(10,2)/nullif(sia.traited_store_count_this_year,0) as numeric(10,2)) as wtd_units_per_traited_store
    --wtd units per traited stores
    ,cast(wtd_sales/nullif(sia.traited_store_count_this_year,0) as numeric(10,2)) as  wtd_sales_per_traited_store
	--wtd sales per traited stores
    ,current_date::date as todays_date
	,division
    ,cat
    ,sub_cat
    ,vendor_nbr_dept
    ,case
        when vendor_nbr_dept = '71'
        and division in('Ameriwood','Dorel Home Products')
        then 'D71 - DHF'
        when vendor_nbr_dept = '71'
        and division = 'Cosco Products'
        then 'D71 - Cosco'
        when vendor_nbr_dept = '12'
        and division = 'Cosco Products'
        then 'D12 - Cosco'
        when vendor_nbr_dept = '79'
        and division = 'Dorel Home Products'
        then 'D79 - DHF'
        else null
        end as department_title
    ,'Daily Report ' ||current_date::date as file_name
from sa
left join sia
on sa.current_item_num::bigint = sia.all_links_item_number
left join wia
on sa.current_item_num::bigint = wia.walmart_item_number
)
;